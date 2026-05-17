import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room.dart';
import '../services/supabase_service.dart';

final roomsProvider = StateNotifierProvider<RoomsNotifier, AsyncValue<List<Room>>>((ref) {
  return RoomsNotifier();
});

class RoomsNotifier extends StateNotifier<AsyncValue<List<Room>>> {
  RoomsNotifier() : super(const AsyncValue.data([]));

  Future<void> loadRooms(String houseId) async {
    state = const AsyncValue.loading();
    try {
      final rooms = await SupabaseService.getRooms(houseId);
      state = AsyncValue.data(rooms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRoom(String name, String houseId) async {
    try {
      final room = await SupabaseService.createRoom(name: name, houseId: houseId);
      final currentRooms = state.value ?? [];
      state = AsyncValue.data([...currentRooms, room]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateRoom(String roomId, String name) async {
    try {
      await SupabaseService.updateRoom(roomId, name);
      final currentRooms = state.value ?? [];
      state = AsyncValue.data(
        currentRooms.map((r) => r.id == roomId ? r.copyWith(name: name) : r).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await SupabaseService.deleteRoom(roomId);
      final currentRooms = state.value ?? [];
      state = AsyncValue.data(currentRooms.where((r) => r.id != roomId).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
