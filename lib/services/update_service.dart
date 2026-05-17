import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateService {
  static const String _repoOwner = 'GiovanniDrago';
  static const String _repoName = 'home_inventory';
  static const String _lastCheckKey = 'last_update_check';
  static const String _delayUntilKey = 'update_delay_until';

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
        ),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latestTag = data['tag_name'] as String? ?? '';
      final latestVersion = latestTag.replaceFirst('v', '');

      // Simple version comparison
      final hasUpdate = _compareVersions(latestVersion, currentVersion) > 0;

      if (hasUpdate) {
        return {
          'currentVersion': currentVersion,
          'latestVersion': latestVersion,
          'tagName': latestTag,
          'releaseUrl': data['html_url'] as String? ?? '',
        };
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> shouldCheckAutomatically() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastCheckKey);
    final delayUntil = prefs.getInt(_delayUntilKey);

    final now = DateTime.now().millisecondsSinceEpoch;

    // Respect delay
    if (delayUntil != null && now < delayUntil) {
      return false;
    }

    // Check once per day
    if (lastCheck != null) {
      final lastCheckDate = DateTime.fromMillisecondsSinceEpoch(lastCheck);
      final difference = DateTime.now().difference(lastCheckDate);
      if (difference.inHours < 24) {
        return false;
      }
    }

    return true;
  }

  static Future<void> markChecked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> setDelayOneDay() async {
    final prefs = await SharedPreferences.getInstance();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await prefs.setInt(_delayUntilKey, tomorrow.millisecondsSinceEpoch);
  }

  static Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).whereType<int>().toList();
    final parts2 = v2.split('.').map(int.tryParse).whereType<int>().toList();

    for (var i = 0; i < parts1.length && i < parts2.length; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }

    if (parts1.length > parts2.length) return 1;
    if (parts1.length < parts2.length) return -1;
    return 0;
  }
}
