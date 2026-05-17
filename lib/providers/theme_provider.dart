import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeOption>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemeOption> {
  static const _key = 'theme_id';

  ThemeNotifier() : super(appThemes.first) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_key);
    if (id != null) {
      state = appThemeById(id);
    }
  }

  Future<void> setTheme(String id) async {
    final option = appThemeById(id);
    state = option;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, id);
  }
}
