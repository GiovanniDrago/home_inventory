import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/opf_credentials.dart';

final opfCredentialsProvider = StateNotifierProvider<OpfCredentialsNotifier, OpfCredentials?>((ref) {
  return OpfCredentialsNotifier();
});

class OpfCredentialsNotifier extends StateNotifier<OpfCredentials?> {
  static const _key = 'opf_credentials';

  OpfCredentialsNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_key);
      if (encoded != null) {
        final decoded = utf8.decode(base64Decode(encoded));
        final map = jsonDecode(decoded) as Map<String, dynamic>;
        state = OpfCredentials.fromMap(map);
      }
    } catch (e) {
      state = null;
    }
  }

  Future<void> save(OpfCredentials credentials) async {
    state = credentials;
    final prefs = await SharedPreferences.getInstance();
    final encoded = base64Encode(utf8.encode(jsonEncode(credentials.toMap())));
    await prefs.setString(_key, encoded);
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  bool get isConfigured => state != null;
}
