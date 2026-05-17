import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_inventory/l10n/app_localizations.dart';

import '../providers/house_provider.dart';
import 'rooms_screen.dart';
import 'settings_screen.dart';
import 'product_form_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final _pages = [
    const RoomsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final houseAsync = ref.watch(houseProvider);

    return Scaffold(
      appBar: AppBar(
        title: houseAsync.when(
          data: (house) => Text(house?.name ?? l10n.appTitle),
          loading: () => const Text('...'),
          error: (_, __) => Text(l10n.appTitle),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () => setState(() => _currentIndex = 0),
              icon: Icon(
                Icons.home_outlined,
                color: _currentIndex == 0
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              tooltip: l10n.inventory,
            ),
            const SizedBox(width: 48), // Space for FAB
            IconButton(
              onPressed: () => setState(() => _currentIndex = 1),
              icon: Icon(
                Icons.settings_outlined,
                color: _currentIndex == 1
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              tooltip: l10n.settings,
            ),
          ],
        ),
      ),
    );
  }
}
