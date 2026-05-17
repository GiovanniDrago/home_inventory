import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/supabase_service.dart';

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, AsyncValue<List<Category>>>((ref) {
  return CategoriesNotifier();
});

class CategoriesNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  CategoriesNotifier() : super(const AsyncValue.data([]));

  Future<void> loadCategories(String houseId) async {
    state = const AsyncValue.loading();
    try {
      final categories = await SupabaseService.getCategories(houseId);
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCategory({
    required String name,
    required String houseId,
    String? description,
  }) async {
    try {
      final category = await SupabaseService.createCategory(
        name: name,
        houseId: houseId,
        description: description,
      );
      final current = state.value ?? [];
      state = AsyncValue.data([...current, category]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCategory(String categoryId, {String? name, String? description}) async {
    try {
      await SupabaseService.updateCategory(categoryId, name: name, description: description);
      final current = state.value ?? [];
      state = AsyncValue.data(
        current.map((c) {
          if (c.id == categoryId) {
            return c.copyWith(
              name: name ?? c.name,
              description: description ?? c.description,
            );
          }
          return c;
        }).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await SupabaseService.deleteCategory(categoryId);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((c) => c.id != categoryId).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> seedDefaults(String houseId) async {
    try {
      await SupabaseService.seedDefaultCategories(houseId);
      await loadCategories(houseId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
