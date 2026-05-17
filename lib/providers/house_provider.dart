import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/house.dart';
import '../services/supabase_service.dart';

final houseProvider = StateNotifierProvider<HouseNotifier, AsyncValue<House?>>((ref) {
  return HouseNotifier();
});

class HouseNotifier extends StateNotifier<AsyncValue<House?>> {
  HouseNotifier() : super(const AsyncValue.data(null));

  Future<void> loadHouse(String? houseId) async {
    if (houseId == null) {
      state = const AsyncValue.data(null);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final house = await SupabaseService.getHouse(houseId);
      state = AsyncValue.data(house);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createHouse({required String name, required String createdBy}) async {
    state = const AsyncValue.loading();
    try {
      final house = await SupabaseService.createHouse(name: name, createdBy: createdBy);
      state = AsyncValue.data(house);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}
