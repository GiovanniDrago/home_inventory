import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invitation.dart';
import '../services/supabase_service.dart';

final invitationsProvider = StateNotifierProvider<InvitationsNotifier, AsyncValue<List<Invitation>>>((ref) {
  return InvitationsNotifier();
});

final sentInvitationsProvider = StateNotifierProvider<SentInvitationsNotifier, AsyncValue<List<Invitation>>>((ref) {
  return SentInvitationsNotifier();
});

class InvitationsNotifier extends StateNotifier<AsyncValue<List<Invitation>>> {
  InvitationsNotifier() : super(const AsyncValue.data([]));

  Future<void> loadInvitations(String userId) async {
    state = const AsyncValue.loading();
    try {
      final invitations = await SupabaseService.getIncomingInvitations(userId);
      state = AsyncValue.data(invitations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> respond(String invitationId, String status) async {
    try {
      await SupabaseService.respondToInvitation(invitationId, status);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((i) => i.id != invitationId).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class SentInvitationsNotifier extends StateNotifier<AsyncValue<List<Invitation>>> {
  SentInvitationsNotifier() : super(const AsyncValue.data([]));

  Future<void> loadSentInvitations(String userId) async {
    state = const AsyncValue.loading();
    try {
      final invitations = await SupabaseService.getSentInvitations(userId);
      state = AsyncValue.data(invitations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendInvitation({
    required String fromUserId,
    required String toEmail,
    required String houseId,
  }) async {
    try {
      final invitation = await SupabaseService.createInvitation(
        fromUserId: fromUserId,
        toEmail: toEmail,
        houseId: houseId,
      );
      final current = state.value ?? [];
      state = AsyncValue.data([invitation, ...current]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
