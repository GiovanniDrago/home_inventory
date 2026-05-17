import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_inventory/l10n/app_localizations.dart';

import '../providers/rooms_provider.dart';
import '../providers/products_provider.dart';
import '../providers/house_provider.dart';
import '../providers/current_room_provider.dart';
import 'room_detail_screen.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final roomsAsync = ref.watch(roomsProvider);

    return roomsAsync.when(
      data: (rooms) {
        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.meeting_room_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noRooms,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rooms.length + 1,
          itemBuilder: (context, index) {
            if (index == rooms.length) {
              return _AddRoomCard();
            }

            final room = rooms[index];
            return _RoomCard(room: room);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _RoomCard extends ConsumerWidget {
  final dynamic room;

  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          ref.read(currentRoomIdProvider.notifier).state = room.id;
          ref.read(productsProvider.notifier).loadProducts(
                room.houseId,
                roomId: room.id,
              );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RoomDetailScreen(room: room),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.room_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      room.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              _ProductPreview(roomId: room.id),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductPreview extends ConsumerWidget {
  final String roomId;

  const _ProductPreview({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      data: (products) {
        final roomProducts = products
            .where((p) => p.roomId == roomId && p.status == 'active')
            .take(4)
            .toList();

        if (roomProducts.isEmpty) {
          return Text(
            AppLocalizations.of(context)!.noProducts,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roomProducts.map((product) {
            return Chip(
              label: Text(
                product.name,
                style: const TextStyle(fontSize: 12),
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AddRoomCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddRoomCard> createState() => _AddRoomCardState();
}

class _AddRoomCardState extends ConsumerState<_AddRoomCard> {
  final _controller = TextEditingController();

  void _showAddDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.addRoom),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: l10n.roomName,
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                if (_controller.text.trim().isNotEmpty) {
                  final houseId = ref.read(houseProvider).value?.id;
                  if (houseId != null) {
                    await ref.read(roomsProvider.notifier).addRoom(
                          _controller.text.trim(),
                          houseId,
                        );
                  }
                }
                _controller.clear();
                if (mounted) Navigator.of(context).pop();
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: _showAddDialog,
        child: SizedBox(
          height: 80,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.addRoom,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
