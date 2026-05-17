import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_inventory/l10n/app_localizations.dart';

import '../models/product.dart';
import '../providers/products_provider.dart';
import '../providers/rooms_provider.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    // Watch for product updates
    final productsAsync = ref.watch(productsProvider);
    Product currentProduct = widget.product;
    productsAsync.whenData((products) {
      final updated = products.firstWhere(
        (p) => p.id == widget.product.id,
        orElse: () => widget.product,
      );
      currentProduct = updated;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(currentProduct.name),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: _isEditing
          ? ProductFormScreen(
              product: currentProduct,
              onSave: () => setState(() => _isEditing = false),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailItem(icon: Icons.label_outline, label: l10n.productName, value: currentProduct.name),
                  if (currentProduct.brand != null)
                    _DetailItem(icon: Icons.branding_watermark_outlined, label: l10n.brand, value: currentProduct.brand!),
                  _DetailItem(icon: Icons.numbers_outlined, label: l10n.quantity, value: currentProduct.quantity.toString()),
                  if (currentProduct.price != null)
                    _DetailItem(
                      icon: Icons.attach_money_outlined,
                      label: l10n.price,
                      value: _formatPrice(currentProduct.price!),
                    ),
                  if (currentProduct.note != null && currentProduct.note!.isNotEmpty)
                    _DetailItem(icon: Icons.notes_outlined, label: l10n.note, value: currentProduct.note!),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showMoveDialog(context, currentProduct),
                          icon: const Icon(Icons.move_to_inbox_outlined),
                          label: Text(l10n.move),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _showTerminateDialog(context, currentProduct),
                          icon: const Icon(Icons.delete_outline),
                          label: Text(l10n.terminate),
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.errorContainer,
                            foregroundColor: scheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  String _formatPrice(double price) {
    if (price == price.toInt()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  void _showMoveDialog(BuildContext context, Product product) {
    final l10n = AppLocalizations.of(context)!;
    final roomsAsync = ref.read(roomsProvider);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.moveToRoom),
          content: roomsAsync.when(
            data: (rooms) {
              final otherRooms = rooms.where((r) => r.id != product.roomId).toList();
              if (otherRooms.isEmpty) {
                return Text('No other rooms available');
              }
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: otherRooms.length,
                  itemBuilder: (context, index) {
                    final room = otherRooms[index];
                    return ListTile(
                      title: Text(room.name),
                      onTap: () async {
                        await ref.read(productsProvider.notifier).moveProduct(product.id, room.id);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Moved to ${room.name}')),
                          );
                        }
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error loading rooms'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }

  void _showTerminateDialog(BuildContext context, Product product) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.terminate),
          content: Text('Are you sure you want to terminate "${product.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                await ref.read(productsProvider.notifier).terminateProduct(product.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to room detail
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.productTerminated)),
                  );
                }
              },
              child: Text(l10n.terminate),
            ),
          ],
        );
      },
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
