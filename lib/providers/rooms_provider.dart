import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/room.dart';
import '../services/supabase_service.dart';

final roomsProvider = StateNotifierProvider<RoomsNotifier, AsyncValue<List<Room>>>((ref) {
  return RoomsNotifier();
});

class RoomsNotifier extends StateNotifier<AsyncValue<List<Room>>> {
  RoomsNotifier() : super(const AsyncValue.data([]));

  static String _orderKey(String houseId) => 'room_order_$houseId';

  Future<void> loadRooms(String houseId) async {
    state = const AsyncValue.loading();
    try {
      final rooms = await SupabaseService.getRooms(houseId);
      state = AsyncValue.data(await _applySavedOrder(houseId, rooms));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<Room>> _applySavedOrder(String houseId, List<Room> rooms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_orderKey(houseId)) ?? [];
      if (saved.isEmpty) return rooms;

      final byId = {for (final room in rooms) room.id: room};
      final ordered = <Room>[];
      for (final id in saved) {
        final room = byId.remove(id);
        if (room != null) ordered.add(room);
      }
      ordered.addAll(rooms.where((room) => byId.containsKey(room.id)));
      return ordered;
    } catch (_) {
      return rooms;
    }
  }

  Future<void> reorderRooms(int oldIndex, int newIndex) async {
    final rooms = state.value;
    if (rooms == null || rooms.isEmpty) return;
    if (oldIndex < 0 || oldIndex >= rooms.length) return;

    final target = newIndex.clamp(0, rooms.length - 1);
    final reordered = [...rooms];
    final room = reordered.removeAt(oldIndex);
    reordered.insert(target, room);
    state = AsyncValue.data(reordered);
    await _persistOrder(room.houseId);
  }

  Future<void> _persistOrder(String houseId) async {
    final rooms = state.value;
    if (rooms == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _orderKey(houseId),
        rooms.map((room) => room.id).toList(),
      );
    } catch (_) {}
  }

  Future<void> addRoom(String name, String houseId) async {
    try {
      final room = await SupabaseService.createRoom(name: name, houseId: houseId);
      final currentRooms = state.value ?? [];
      state = AsyncValue.data([...currentRooms, room]);
      await _persistOrder(houseId);
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
      final deleted = currentRooms.where((r) => r.id == roomId).toList();
      state = AsyncValue.data(currentRooms.where((r) => r.id != roomId).toList());
      if (deleted.isNotEmpty) {
        await _persistOrder(deleted.first.houseId);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
