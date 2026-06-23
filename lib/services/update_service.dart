import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../l10n/app_localizations.dart';

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
