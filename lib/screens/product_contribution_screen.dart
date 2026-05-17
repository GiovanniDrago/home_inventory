import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:home_inventory/l10n/app_localizations.dart';

import '../providers/opf_credentials_provider.dart';
import '../services/opf_contribution_service.dart';
import 'opf_settings_screen.dart';

class ProductContributionScreen extends ConsumerStatefulWidget {
  final String barcode;

  const ProductContributionScreen({super.key, required this.barcode});

  @override
  ConsumerState<ProductContributionScreen> createState() => _ProductContributionScreenState();
}

class _ProductContributionScreenState extends ConsumerState<ProductContributionScreen> {
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _quantityController = TextEditingController();
  final _categoryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  XFile? _pickedImage;
  Uint8List? _resizedPhotoBytes;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImage = image;
        _resizedPhotoBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final credentials = ref.read(opfCredentialsProvider);
    if (credentials == null) {
      _showCredentialsDialog();
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await OpfContributionService.submitProduct(
      credentials: credentials,
      barcode: widget.barcode,
      productName: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      quantity: _quantityController.text.trim().isEmpty ? null : _quantityController.text.trim(),
      category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      photoBytes: _resizedPhotoBytes,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      final result = {
        'barcode': widget.barcode,
        'name': _nameController.text.trim(),
        'brand': _brandController.text.trim(),
        'quantity': int.tryParse(_quantityController.text) ?? 1,
      };
      Navigator.of(context).pop(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit. Please try again.')),
      );
    }
  }

  void _showCredentialsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text(
          'Please configure your Open Products Facts login in Settings to contribute products.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OpfSettingsScreen()),
              );
            },
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Missing Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barcode (read-only)
              TextFormField(
                initialValue: widget.barcode,
                decoration: const InputDecoration(
                  labelText: 'Barcode',
                  prefixIcon: Icon(Icons.qr_code),
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),
              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.productName,
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Brand
              TextFormField(
                controller: _brandController,
                decoration: InputDecoration(
                  labelText: l10n.brand,
                  prefixIcon: const Icon(Icons.branding_watermark_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: l10n.quantity,
                  prefixIcon: const Icon(Icons.numbers_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Category
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: l10n.category,
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 24),
              // Photo
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(_pickedImage == null ? 'Take Front Photo' : 'Retake Photo'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
              if (_resizedPhotoBytes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _resizedPhotoBytes!,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              // Submit
              if (_isSubmitting)
                const Center(child: CircularProgressIndicator())
              else
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Submit to Open Products Facts'),
                ),
              const SizedBox(height: 12),
              Text(
                'Your contribution will be reviewed and added to the Open Products Facts database.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
