import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_inventory/l10n/app_localizations.dart';

import '../models/room.dart';
import '../models/category.dart';
import '../providers/rooms_provider.dart';
import '../providers/products_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/current_room_provider.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final Room room;

  const RoomDetailScreen({super.key, required this.room});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  bool _isEditing = false;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.room.name;
    // Load products for this room
    Future.microtask(() {
      ref.read(currentRoomIdProvider.notifier).state = widget.room.id;
      ref.read(productsProvider.notifier).loadProducts(
            widget.room.houseId,
            roomId: widget.room.id,
          );
      ref.read(categoriesProvider.notifier).loadCategories(widget.room.houseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(filteredProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategories = ref.watch(selectedCategoryFiltersProvider);

    // Watch rooms provider to get updated room name
    final roomsAsync = ref.watch(roomsProvider);
    String currentRoomName = widget.room.name;
    roomsAsync.whenData((rooms) {
      final updatedRoom = rooms.firstWhere(
        (r) => r.id == widget.room.id,
        orElse: () => widget.room,
      );
      currentRoomName = updatedRoom.name;
    });

    return Scaffold(
      appBar: AppBar(
        title: _isEditing
            ? TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: l10n.roomName,
                  border: InputBorder.none,
                ),
                autofocus: true,
              )
            : Text(currentRoomName),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: () async {
                if (_nameController.text.trim().isNotEmpty) {
                  await ref.read(roomsProvider.notifier).updateRoom(
                        widget.room.id,
                        _nameController.text.trim(),
                      );
                  setState(() => _isEditing = false);
                }
              },
              icon: const Icon(Icons.check),
            )
          else
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ProductFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.search,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                ref.read(productSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          // Category filters
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category selector button
                    OutlinedButton.icon(
                      onPressed: () => _showCategorySelector(context, categories, selectedCategories),
                      icon: const Icon(Icons.category_outlined),
                      label: Text(
                        selectedCategories.isEmpty
                            ? l10n.category
                            : '${l10n.category}: ${selectedCategories.length}',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    // Selected category chips
                    if (selectedCategories.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedCategories.map((catId) {
                            final category = categories.firstWhere(
                              (c) => c.id == catId,
                              orElse: () => categories.first,
                            );
                            return InputChip(
                              label: Text(category.name),
                              onDeleted: () {
                                final newSet = Set<String>.from(selectedCategories);
                                newSet.remove(catId);
                                ref.read(selectedCategoryFiltersProvider.notifier).state = newSet;
                              },
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Product list
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noProducts,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${product.quantity}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                          ),
                        ),
                        title: Text(product.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.price != null)
                              Text(
                                _formatPrice(product.price!),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (product.brand != null)
                              Text(
                                product.brand!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: product.price != null && product.brand != null,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategorySelector(BuildContext context, List<Category> categories, Set<String> selectedIds) {
    final l10n = AppLocalizations.of(context)!;
    final localSelected = Set<String>.from(selectedIds);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.category),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = localSelected.contains(category.id);
                    return CheckboxListTile(
                      title: Text(category.name),
                      value: isSelected,
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true) {
                            localSelected.add(category.id);
                          } else {
                            localSelected.remove(category.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    ref.read(selectedCategoryFiltersProvider.notifier).state = localSelected;
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatPrice(double price) {
    // Remove trailing zeros
    if (price == price.toInt()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}
