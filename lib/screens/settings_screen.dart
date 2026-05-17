import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_inventory/l10n/app_localizations.dart';

import 'package:url_launcher/url_launcher.dart';

import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/house_provider.dart';
import '../services/update_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'categories_screen.dart';
import 'invitations_screen.dart';
import 'opf_settings_screen.dart';
import 'auth_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeNotifier = ref.read(themeProvider.notifier);
    final localeNotifier = ref.read(localeProvider.notifier);
    final profileAsync = ref.watch(profileProvider);

    return ListView(
      children: [
        // Profile
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(l10n.profile),
          subtitle: profileAsync.when(
            data: (profile) => Text(profile?.nickname ?? ''),
            loading: () => const Text('...'),
            error: (_, __) => const Text(''),
          ),
        ),
        const Divider(),
        // Theme
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: Text(l10n.themeLabel),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: appThemes.map((t) {
              return ActionChip(
                label: Text(t.name),
                onPressed: () => themeNotifier.setTheme(t.id),
              );
            }).toList(),
          ),
        ),
        const Divider(),
        // Language
        ListTile(
          leading: const Icon(Icons.language_outlined),
          title: Text(l10n.languageLabel),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('English'),
                onPressed: () => localeNotifier.setLocale(const Locale('en')),
              ),
              ActionChip(
                label: const Text('Italiano'),
                onPressed: () => localeNotifier.setLocale(const Locale('it')),
              ),
            ],
          ),
        ),
        const Divider(),
        // Categories
        ListTile(
          leading: const Icon(Icons.category_outlined),
          title: Text(l10n.manageCategories),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            );
          },
        ),
        const Divider(),
        // Invitations
        ListTile(
          leading: const Icon(Icons.mail_outline),
          title: Text(l10n.invitations),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InvitationsScreen()),
            );
          },
        ),
        const Divider(),
        // Open Products Facts Login
        ListTile(
          leading: const Icon(Icons.cloud_upload_outlined),
          title: const Text('Open Products Facts Login'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OpfSettingsScreen()),
            );
          },
        ),
        const Divider(),
        // Check Updates
        ListTile(
          leading: const Icon(Icons.system_update_outlined),
          title: Text(l10n.checkUpdates),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _checkUpdates(context),
        ),
        // Version
        FutureBuilder<String>(
          future: UpdateService.getCurrentVersion(),
          builder: (context, snapshot) {
            return ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.version),
              subtitle: Text(snapshot.data ?? '...'),
            );
          },
        ),
        const Divider(),
        // Log Out
        ListTile(
          leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
          title: Text(l10n.logOut, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          onTap: () => _showLogoutDialog(context, ref),
        ),
      ],
    );
  }

  Future<void> _checkUpdates(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final update = await UpdateService.checkForUpdate();
    await UpdateService.markChecked();

    if (!context.mounted) return;

    if (update != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.updateAvailable),
          content: Text(
            '${l10n.newVersion}\n\nCurrent: ${update['currentVersion']}\nLatest: ${update['latestVersion']}',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await UpdateService.setDelayOneDay();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(l10n.remindTomorrow),
            ),
            FilledButton(
              onPressed: () async {
                final url = Uri.parse(update['releaseUrl'] as String);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(l10n.openReleasePage),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noUpdate)),
      );
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logOut),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              await SupabaseService.signOut();
              ref.read(houseProvider.notifier).clear();
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
  }
}
