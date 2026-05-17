import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';

final productsProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductsNotifier();
});

final productSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryFiltersProvider = StateProvider<Set<String>>((ref) => {});

class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  ProductsNotifier() : super(const AsyncValue.data([]));

  Future<void> loadProducts(String houseId, {String? roomId}) async {
    state = const AsyncValue.loading();
    try {
      final products = await SupabaseService.getProducts(houseId, roomId: roomId);
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addProduct({
    required String name,
    String? brand,
    String? note,
    required int quantity,
    double? price,
    required String roomId,
    String? categoryId,
    required String houseId,
  }) async {
    try {
      final product = await SupabaseService.createProduct(
        name: name,
        brand: brand,
        note: note,
        quantity: quantity,
        price: price,
        roomId: roomId,
        categoryId: categoryId,
        houseId: houseId,
      );
      final current = state.value ?? [];
      state = AsyncValue.data([product, ...current]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProduct(String productId, {
    String? name,
    String? brand,
    String? note,
    int? quantity,
    double? price,
    String? roomId,
    String? categoryId,
  }) async {
    try {
      await SupabaseService.updateProduct(
        productId,
        name: name,
        brand: brand,
        note: note,
        quantity: quantity,
        price: price,
        roomId: roomId,
        categoryId: categoryId,
      );
      final current = state.value ?? [];
      state = AsyncValue.data(
        current.map((p) {
          if (p.id == productId) {
            return p.copyWith(
              name: name ?? p.name,
              brand: brand ?? p.brand,
              note: note ?? p.note,
              quantity: quantity ?? p.quantity,
              price: price ?? p.price,
              roomId: roomId ?? p.roomId,
              categoryId: categoryId ?? p.categoryId,
            );
          }
          return p;
        }).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> moveProduct(String productId, String newRoomId) async {
    try {
      await SupabaseService.moveProduct(productId, newRoomId);
      final current = state.value ?? [];
      state = AsyncValue.data(
        current.map((p) => p.id == productId ? p.copyWith(roomId: newRoomId) : p).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> terminateProduct(String productId) async {
    try {
      await SupabaseService.terminateProduct(productId);
      final current = state.value ?? [];
      state = AsyncValue.data(
        current.map((p) => p.id == productId ? p.copyWith(status: 'terminated') : p).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final searchQuery = ref.watch(productSearchQueryProvider).toLowerCase();
  final selectedCategories = ref.watch(selectedCategoryFiltersProvider);

  return productsAsync.when(
    data: (products) {
      var filtered = products.where((p) => p.status == 'active').toList();

      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((p) {
          return p.name.toLowerCase().contains(searchQuery) ||
              (p.brand?.toLowerCase().contains(searchQuery) ?? false) ||
              (p.note?.toLowerCase().contains(searchQuery) ?? false);
        }).toList();
      }

      if (selectedCategories.isNotEmpty) {
        filtered = filtered.where((p) {
          return p.categoryId != null && selectedCategories.contains(p.categoryId);
        }).toList();
      }

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
