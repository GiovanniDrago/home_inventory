import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_inventory/l10n/app_localizations.dart';

import '../providers/invitations_provider.dart';
import '../providers/auth_provider.dart';

class InvitationsScreen extends ConsumerStatefulWidget {
  const InvitationsScreen({super.key});

  @override
  ConsumerState<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends ConsumerState<InvitationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = ref.read(authStateProvider).value?.session?.user.id;
      if (userId != null) {
        ref.read(invitationsProvider.notifier).loadInvitations(userId);
        ref.read(sentInvitationsProvider.notifier).loadSentInvitations(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final incomingAsync = ref.watch(invitationsProvider);
    final sentAsync = ref.watch(sentInvitationsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.invitations),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.incomingInvitations),
              Tab(text: l10n.sentInvitations),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Incoming
            incomingAsync.when(
              data: (invitations) {
                if (invitations.isEmpty) {
                  return _EmptyState(icon: Icons.inbox_outlined, message: 'No incoming invitations');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: invitations.length,
                  itemBuilder: (context, index) {
                    final inv = invitations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.createdBy}: ${inv.fromUserNickname ?? 'Unknown'}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text('${l10n.house}: ${inv.houseName ?? 'Unknown'}'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      await ref.read(invitationsProvider.notifier).respond(inv.id, 'rejected');
                                    },
                                    child: Text(l10n.decline),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () async {
                                      await ref.read(invitationsProvider.notifier).respond(inv.id, 'accepted');
                                    },
                                    child: Text(l10n.accept),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
            // Sent
            sentAsync.when(
              data: (invitations) {
                if (invitations.isEmpty) {
                  return _EmptyState(icon: Icons.send_outlined, message: 'No sent invitations');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: invitations.length,
                  itemBuilder: (context, index) {
                    final inv = invitations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text('${l10n.house}: ${inv.houseName ?? 'Unknown'}'),
                        subtitle: Text('To: ${inv.toEmail}'),
                        trailing: Chip(
                          label: Text(
                            inv.status == 'pending' ? l10n.pending : l10n.rejected,
                          ),
                          backgroundColor: inv.status == 'pending'
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.errorContainer,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
