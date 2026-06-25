import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/supabase_service.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return SupabaseService.currentUser;
});

final authLoadingProvider = StateProvider<bool>((ref) => false);

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<Profile?>>((ref) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<AsyncValue<Profile?>> {
  ProfileNotifier() : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final profile = await SupabaseService.getProfile(userId);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadProfile();
  }

  Future<void> setHouse(String? houseId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Not authenticated');
    await SupabaseService.updateProfileHouse(userId, houseId);
    await refresh();
  }
}
