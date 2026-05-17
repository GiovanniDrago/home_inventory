import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_inventory/l10n/app_localizations.dart';

import '../models/product.dart';
import '../providers/products_provider.dart';
import '../providers/rooms_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/current_room_provider.dart';
import '../providers/house_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;
  final VoidCallback? onSave;

  const ProductFormScreen({super.key, this.product, this.onSave});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _noteController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  String? _selectedRoomId;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _nameController.text = product.name;
      _brandController.text = product.brand ?? '';
      _noteController.text = product.note ?? '';
      _quantityController.text = product.quantity.toString();
      if (product.price != null) {
        _priceController.text = _formatPriceForEdit(product.price!);
      }
      _selectedRoomId = product.roomId;
      _selectedCategoryId = product.categoryId;
    } else {
      // For new product, determine room preselection
      final currentRoomId = ref.read(currentRoomIdProvider);
      final rooms = ref.read(roomsProvider).value ?? [];
      if (rooms.length == 1) {
        _selectedRoomId = rooms.first.id;
      } else if (currentRoomId != null) {
        _selectedRoomId = currentRoomId;
      }
    }
  }

  String _formatPriceForEdit(double price) {
    if (price == price.toInt()) {
      return price.toInt().toString();
    }
    return price.toString();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final houseId = ref.read(houseProvider).value?.id;
    if (houseId == null) return;

    final name = _nameController.text.trim();
    final brand = _brandController.text.trim().isEmpty ? null : _brandController.text.trim();
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final price = _priceController.text.isEmpty
        ? null
        : double.tryParse(_priceController.text.replaceAll(',', '.'));

    if (widget.product != null) {
      // Update existing
      await ref.read(productsProvider.notifier).updateProduct(
            widget.product!.id,
            name: name,
            brand: brand,
            note: note,
            quantity: quantity,
            price: price,
            roomId: _selectedRoomId,
            categoryId: _selectedCategoryId,
          );
      widget.onSave?.call();
    } else {
      // Create new
      if (_selectedRoomId == null) return;
      await ref.read(productsProvider.notifier).addProduct(
            name: name,
            brand: brand,
            note: note,
            quantity: quantity,
            price: price,
            roomId: _selectedRoomId!,
            categoryId: _selectedCategoryId,
            houseId: houseId,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final roomsAsync = ref.watch(roomsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.edit : l10n.addProduct),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Room dropdown
              roomsAsync.when(
                data: (rooms) {
                  return DropdownButtonFormField<String>(
                    value: _selectedRoomId,
                    decoration: InputDecoration(
                      labelText: l10n.selectRoom,
                      prefixIcon: const Icon(Icons.room_outlined),
                    ),
                    items: rooms.map((room) {
                      return DropdownMenuItem(
                        value: room.id,
                        child: Text(room.name),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedRoomId = value),
                    validator: (value) {
                      if (value == null) return l10n.requiredField;
                      return null;
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => Text(l10n.requiredField),
              ),
              const SizedBox(height: 16),
              // Name
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
              ),
              const SizedBox(height: 16),
              // Quantity and Price row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: l10n.quantity,
                        prefixIcon: const Icon(Icons.numbers_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.requiredField;
                        }
                        final num = int.tryParse(value);
                        if (num == null || num < 1) {
                          return 'Min 1';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: l10n.price,
                        prefixIcon: const Icon(Icons.attach_money_outlined),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Category dropdown
              categoriesAsync.when(
                data: (categories) {
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: l10n.category,
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('—'),
                      ),
                      ...categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }),
                    ],
                    onChanged: (value) => setState(() => _selectedCategoryId = value),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              // Note
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: l10n.note,
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (isEditing) {
                          widget.onSave?.call();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(l10n.save),
                    ),
                  ),
                ],
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
    _noteController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
