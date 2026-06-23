---
name: flutter-update-checker
description: Adds a GitHub Releases-based update checker to an open-source Flutter Android app with daily silent checks, manual checks in Settings, and a download-via-browser confirmation dialog.
---

# When to use
Use this skill when the user asks to:
- "Implement update checking" / "add an update checker" / "add update functionality"
- "Refactor the update check" / "fix the update mechanism"
- "Add automatic app updates" / "add daily update check" / "check for app updates"
- Any similar request involving version update detection in an open-source Flutter Android app

This skill is designed for **open-source Flutter Android apps that publish releases to GitHub**. It works alongside `flutter-github-deploy` (which produces signed APK/AAB assets on GitHub Releases). The typical pairing is: `flutter-github-deploy` creates the releases → `flutter-update-checker` detects them in the running app and prompts the user to download.

This skill is **not** for closed-source apps, apps distributed through a Play Store-only channel, or apps that need in-app APK installation.

# What this update checker contains

- **`lib/services/update_service.dart`** — static `UpdateService` class that fetches the latest GitHub release, compares versions, and shows a Material 3 `AlertDialog` when an update is available
- **`lib/config.dart`** — `githubOwner` and `githubRepo` constants (auto-detected from `git remote` on first use)
- **Localization entries** for English and Italian (7 keys: check for updates, update available, no updates, update error, download, later, version)
- **Settings screen integration** — a `ListTile` for manual checking and a `FutureBuilder` showing the current version
- **App startup daily check** — a `_AppStartupWrapper` widget that calls `UpdateService.check(context, silent: true)` on the first frame, guarded by a once-per-day throttle
- **Dependencies**: `http`, `package_info_plus`, `url_launcher`, `shared_preferences`

The user experience:
1. App launches → silent check runs once per day. If an update is found, an `AlertDialog` appears.
2. User opens Settings → taps "Check for updates" → manual check always runs.
3. If no update is found: a `SnackBar` says "No updates available" (manual check only).
4. If an update is found: an `AlertDialog` shows "Update available vX.Y.Z" with two buttons:
   - **Later** (`TextButton`) — dismisses the dialog.
   - **Download** (`FilledButton`) — opens the APK download URL in the device's browser via `url_launcher` with `LaunchMode.externalApplication`.
5. The user installs the APK from the browser download (no in-app installation).

# Source patterns to mirror

Mirror these patterns exactly. Only adapt placeholder values (owner, repo) and integrate into the existing project structure.

## lib/services/update_service.dart

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../l10n/generated/app_localizations.dart';

class UpdateService {
  static const String _owner = AppConfig.githubOwner;
  static const String _repo = AppConfig.githubRepo;
  static const String _lastCheckKey = 'last_update_check';

  static String? _cachedVersion;

  static Future<String> _getCurrentVersion() async {
    if (_cachedVersion != null) return _cachedVersion!;
    final packageInfo = await PackageInfo.fromPlatform();
    _cachedVersion = packageInfo.version;
    return _cachedVersion!;
  }

  /// Exposes the installed app version read from platform metadata.
  static Future<String> get currentVersion async => _getCurrentVersion();

  static Future<void> check(BuildContext context, {bool silent = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString(_lastCheckKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (silent && lastCheck == today) return;

    final latest = await _fetchLatestRelease();
    final currentVersion = await _getCurrentVersion();

    if (!silent) {
      await prefs.setString(_lastCheckKey, today);
    } else if (latest != null && _isNewer(latest.version, currentVersion)) {
      await prefs.setString(_lastCheckKey, today);
    }

    if (latest == null) {
      if (!silent && context.mounted) {
        _showSnack(context, AppLocalizations.of(context)!.updateError);
      }
      return;
    }

    if (_isNewer(latest.version, currentVersion)) {
      if (context.mounted) {
        _showUpdateDialog(context, latest);
      }
    } else if (!silent && context.mounted) {
      _showSnack(context, AppLocalizations.of(context)!.noUpdates);
    }
  }

  static Future<_ReleaseInfo?> _fetchLatestRelease() async {
    try {
      final currentVersion = await _getCurrentVersion();
      final uri = Uri.parse(
        'https://api.github.com/repos/$_owner/$_repo/releases/latest',
      );
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/vnd.github+json',
          'User-Agent': '$_repo/$currentVersion',
        },
      );
      if (response.statusCode != 200) {
        debugPrint('GitHub API error: ${response.statusCode} ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String?;
      final assets = data['assets'] as List<dynamic>?;

      if (tagName == null) return null;

      String? downloadUrl;
      if (assets != null && assets.isNotEmpty) {
        downloadUrl = assets.first['browser_download_url'] as String?;
      }

      return _ReleaseInfo(
        version: tagName.replaceFirst('v', ''),
        downloadUrl:
            downloadUrl ?? 'https://github.com/$_owner/$_repo/releases/latest',
      );
    } catch (e, stack) {
      debugPrint('Update check error: $e');
      debugPrint('$stack');
      return null;
    }
  }

  static bool _isNewer(String latest, String current) {
    final l = latest.split('+').first.split('.').map(int.tryParse).toList();
    final c = current.split('+').first.split('.').map(int.tryParse).toList();

    for (int i = 0; i < 3; i++) {
      final li = i < l.length ? (l[i] ?? 0) : 0;
      final ci = i < c.length ? (c[i] ?? 0) : 0;
      if (li > ci) return true;
      if (li < ci) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context, _ReleaseInfo release) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${l10n.updateAvailable} v${release.version}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.later),
          ),
          FilledButton(
            onPressed: () async {
              final uri = Uri.parse(release.downloadUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  _showSnack(
                    context,
                    AppLocalizations.of(context)!.updateError,
                  );
                }
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.download),
          ),
        ],
      ),
    );
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ReleaseInfo {
  final String version;
  final String downloadUrl;
  _ReleaseInfo({required this.version, required this.downloadUrl});
}
```

**Important:** The import `import '../l10n/generated/app_localizations.dart';` assumes the project uses Flutter's code-generated localization with ARB files. If the project uses a different localization approach (e.g., `easy_localization`, manual string maps, or a different generated path), adjust the import and the `AppLocalizations.of(context)!` calls accordingly. The code-gen approach (`flutter gen-l10n`) is the standard for projects scaffolded with `flutter-android-starter`.

## lib/config.dart

If `lib/config.dart` already exists, add only the `githubOwner` and `githubRepo` fields inside the existing class. If it does not exist, create it with this structure:

```dart
final class AppConfig {
  AppConfig._();

  // GitHub (update checker)
  static const githubOwner = '<github-owner>';
  static const githubRepo = '<github-repo>';
}
```

**First-use autodetection:** Run `git remote get-url origin` in the project root and parse the result to extract the owner and repo name. For example:
- URL `https://github.com/GiovanniDrago/cheap_cheap.git` → owner: `GiovanniDrago`, repo: `cheap_cheap`
- URL `git@github.com:GiovanniDrago/cheap_cheap.git` → owner: `GiovanniDrago`, repo: `cheap_cheap`

## Localization entries (ARB files)

If the project uses Flutter code-generated localization, add these entries. Otherwise, adapt them to the project's localization pattern.

### lib/l10n/app_en.arb — add these keys

```json
{
  "checkForUpdates": "Check for updates",
  "updateAvailable": "Update available",
  "noUpdates": "No updates available",
  "updateError": "Could not check for updates",
  "download": "Download",
  "later": "Later",
  "version": "Version"
}
```

### lib/l10n/app_it.arb — add these keys

```json
{
  "checkForUpdates": "Controlla aggiornamenti",
  "updateAvailable": "Aggiornamento disponibile",
  "noUpdates": "Nessun aggiornamento disponibile",
  "updateError": "Impossibile controllare gli aggiornamenti",
  "download": "Scarica",
  "later": "Più tardi",
  "version": "Versione"
}
```

If the project does not have ARB files yet or uses a different approach, create equivalent string constants or use the project's existing localization mechanism.

## Settings screen snippet

Add this section inside the existing settings screen `ListView` or `SingleChildScrollView`, typically near the bottom of the settings list:

```dart
const SizedBox(height: 24),
Text(
  strings.version,                      // "Version"
  style: Theme.of(context).textTheme.titleLarge,
),
const SizedBox(height: 8),
ListTile(
  leading: const Icon(Icons.system_update),
  title: Text(strings.checkForUpdates),  // "Check for updates"
  onTap: () => UpdateService.check(context, silent: false),
),
FutureBuilder<String>(
  future: UpdateService.currentVersion,
  builder: (context, snapshot) {
    final version = snapshot.data ?? '';
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: Text(strings.version),
      subtitle: version.isNotEmpty ? Text('v$version') : null,
    );
  },
),
```

**Adaptation note:** The variable `strings` refers to the localization object (e.g., `AppLocalizations.of(context)!`). Adjust the variable name to match the project's convention.

## App startup daily check (add a wrapper widget)

In the file that sets the `home:` of `MaterialApp` (typically `lib/app.dart`), wrap the home screen widget with `_AppStartupWrapper`. Add the wrapper class to the same file.

```dart
// Inside the MaterialApp declaration, change:
//   home: const HomePage(),
// to:
//   home: const _AppStartupWrapper(child: HomePage()),

// Then add this class at the bottom of the same file (above the closing brace of
// the file or inside the file scope, not inside another class):

/// Triggers a silent update check once on startup if not already checked today.
class _AppStartupWrapper extends StatefulWidget {
  final Widget child;
  const _AppStartupWrapper({required this.child});

  @override
  State<_AppStartupWrapper> createState() => _AppStartupWrapperState();
}

class _AppStartupWrapperState extends State<_AppStartupWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.check(context, silent: true);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

Add the necessary import at the top of this file:

```dart
import 'services/update_service.dart';
```

## pubspec.yaml — dependency additions

Add these packages to the `dependencies` section. Merge with existing entries — do not duplicate packages that are already listed at potentially different versions:

```yaml
  http: ^1.3.0
  package_info_plus: ^9.0.1
  url_launcher: ^6.3.1
  shared_preferences: ^2.3.2
```

# Workflow

## Phase 1: Detect GitHub owner and repo
- [ ] Run `git remote get-url origin` in the project root.
- [ ] Parse the URL to extract the GitHub owner and repository name.
  - `https://github.com/<owner>/<repo>.git` → use `<owner>` and `<repo>`
  - `git@github.com:<owner>/<repo>.git` → use `<owner>` and `<repo>`
- [ ] If the command fails or no remote is configured, ask the user for the GitHub owner and repo name.

## Phase 2: Add dependencies
- [ ] Read the existing `pubspec.yaml`.
- [ ] Add `http`, `package_info_plus`, `url_launcher`, and `shared_preferences` if not already present.
- [ ] Run `flutter pub get`.

## Phase 3: Create config constants
- [ ] Check if `lib/config.dart` exists.
- [ ] If it exists, add `static const githubOwner` and `static const githubRepo` to the existing class.
- [ ] If it does not exist, create the file with the structure shown above.
- [ ] Fill in the owner and repo values from Phase 1.

## Phase 4: Create update_service.dart
- [ ] Create `lib/services/update_service.dart` with the full code block shown above.
- [ ] Verify the import path for `AppConfig` matches the project structure.
- [ ] Verify the import path for `AppLocalizations` matches the generated localization path. If the project uses a different localization approach, adapt the `AppLocalizations.of(context)!` calls to the project's string lookup mechanism.

## Phase 5: Add localization strings
- [ ] If the project uses ARB files, add the 7 keys to `lib/l10n/app_en.arb` and the Italian translations to `lib/l10n/app_it.arb`.
- [ ] If the project uses a different localization approach, add equivalent string resources using the project's existing pattern.
- [ ] Run `flutter gen-l10n` to regenerate the localization code.

## Phase 6: Wire up the settings screen
- [ ] Locate the settings screen file (commonly `lib/screens/settings_screen.dart` or `lib/ui/settings_screen.dart`).
- [ ] Add the import for `update_service.dart` at the top of the file.
- [ ] Add the "Version" section with the manual check `ListTile` and the version display `FutureBuilder`, following the snippet above.
- [ ] Adapt variable names (`strings` → `l10n`, etc.) to match the project's conventions.

## Phase 7: Wire up the daily check on app startup
- [ ] Locate the file where `MaterialApp` is defined and its `home:` property is set (commonly `lib/app.dart`).
- [ ] Add `import 'services/update_service.dart';` at the top.
- [ ] Wrap the `home:` widget with `_AppStartupWrapper(child: ...)`.
- [ ] Add the `_AppStartupWrapper` class and its state class to the same file.
- [ ] Confirm that `WidgetsBinding.instance.addPostFrameCallback` is used (not a direct call in `initState`) to ensure a valid `BuildContext`.

## Phase 8: Verify
- [ ] Run `flutter pub get`.
- [ ] Run `flutter gen-l10n` (if using ARB localization).
- [ ] Run `flutter analyze` and fix any issues.
- [ ] Confirm the app compiles without errors (`flutter build apk --debug`).
- [ ] Verify that `lib/services/update_service.dart` compiles and the imports resolve correctly.

# Adaptation rules
Apply only minimal adaptations. Keep the update service structure identical.

- Keep the `UpdateService` as a **static class**. Do not convert it to a provider, service locator, or instantiable class unless the user explicitly asks.
- Keep the `_AppStartupWrapper` pattern. Do not move the daily check into a `SplashScreen` timer or a background isolate unless the user explicitly asks.
- Keep `shared_preferences` as the persistence layer for the daily throttle. Do not swap it to Hive, ObjectBox, or SQLite unless the user explicitly asks.
- Keep the `AlertDialog` with `TextButton` ("Later") and `FilledButton` ("Download"). Do not change to a bottom sheet, snackbar-only flow, or in-app download unless the user explicitly asks.
- Keep `url_launcher` with `LaunchMode.externalApplication` for the browser redirect. Do not implement in-app APK downloading or `OpenFile`-based installation.
- Keep `http` as the HTTP client. Do not swap to `dio` unless the project already uses it and the user asks to align.
- The `_lastCheckKey` SharedPreferences key must remain `'last_update_check'`. Do not rename it.
- If the project already has an `AppConfig` class, add only the two GitHub fields without restructuring the existing class.
- If the project uses `AppLocalizations` from a different package path, adjust the import. Only the import path changes — the `AppLocalizations.of(context)!` usage stays the same.

# Integration with flutter-github-deploy

This skill is designed to work with the `flutter-github-deploy` skill, which sets up tag-driven GitHub Actions releases with signed ABI-split APKs. The typical pairing:

1. **`flutter-github-deploy`** creates the release infrastructure — pushing a `v*` tag triggers a CI build that uploads APK assets to a GitHub Release.
2. **`flutter-update-checker`** (this skill) detects those releases inside the running app, notifies the user, and directs them to the browser download.

After applying this skill:
- Check whether `flutter-github-deploy` is available in the OpenCode skills registry.
- If available and not yet applied, mention to the user that `flutter-github-deploy` can be applied to set up the release side of the update flow.
- If already applied, confirm that `githubOwner`/`githubRepo` match the same repository used in the GitHub Actions workflow.
- If not available, remind the user that GitHub releases with APK assets are required for the update checker to find updates. Without tagged releases, `_fetchLatestRelease()` will return no results or point to an empty release page.

# Important caveats

- **GitHub API rate limiting**: The GitHub Releases API has a rate limit of 60 requests per hour for unauthenticated requests. The daily throttle prevents this from being an issue in normal use, but repeated manual checks in quick succession could hit the limit.
- **The daily throttle is date-based, not time-based**: The guard key stores the ISO date string (YYYY-MM-DD). If the app is opened multiple times on the same day, only the first launch triggers a network call. On the next calendar day, the network call runs again regardless of how many hours have passed.
- **First launch behavior**: On the very first launch (no `last_update_check` key), the silent check always runs. This is intentional — it immediately tells the user if they need to update.
- **No in-app installation**: The "Download" button opens the device's browser. The user must manually install the APK from the browser's download manager. On newer Android versions, the browser may additionally prompt the user to allow "install from unknown sources" for that browser.
- **Release assets must be published**: `_fetchLatestRelease()` prefers `assets[0].browser_download_url`. If a GitHub Release has no assets (e.g., only a tag with release notes), it falls back to the release page URL. For the best user experience, ensure releases include APK assets (which `flutter-github-deploy` handles).
- **Localization dependency**: The `update_service.dart` code imports generated localization classes. If the project does not use ARB-based localization, the import and `AppLocalizations.of(context)!` calls must be replaced with the project's string lookup mechanism before the code compiles.
- **Startup wrapper placement**: The `_AppStartupWrapper` must wrap the `home:` widget, not the entire `MaterialApp`. Wrapping `MaterialApp` would prevent `Navigator` from working correctly inside the wrapper.

# Implementation checklist for OpenCode

- run `git remote get-url origin` to detect GitHub owner and repo; ask user if unavailable
- add `http`, `package_info_plus`, `url_launcher`, `shared_preferences` to `pubspec.yaml`
- run `flutter pub get`
- create or update `lib/config.dart` with `githubOwner` and `githubRepo` constants
- create `lib/services/update_service.dart` with the full UpdateService class
- adapt the AppLocalizations import path if the project uses a different localization approach
- add 7 ARB keys to `app_en.arb` and `app_it.arb` (or equivalent localization files)
- run `flutter gen-l10n` if the project uses ARB files
- locate the settings screen file and add the "Version" section with manual check ListTile and FutureBuilder
- locate the app entry point (MaterialApp home:) and wrap with _AppStartupWrapper
- add the _AppStartupWrapper class to the same file
- run `flutter analyze` and fix any issues
- verify the app builds with `flutter build apk --debug`
- check whether `flutter-github-deploy` is available; if so, note the pairing

# Expected outcome
After applying this skill, the Flutter app should:

- Check for updates silently once per day on app startup, showing an `AlertDialog` only when a newer GitHub release is found.
- Provide a "Version" section in Settings with a manual "Check for updates" button and a read-only current version display.
- Use a clean Material 3 `AlertDialog` with "Later" (`TextButton`) and "Download" (`FilledButton`) for update notifications.
- Open the APK download in the device's browser (not an in-app download).
- Have full English and Italian localization for all update-related UI strings.
- Be ready to pair with `flutter-github-deploy` for a complete build-and-distribute pipeline.
