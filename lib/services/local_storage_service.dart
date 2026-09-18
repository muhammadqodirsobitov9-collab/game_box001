import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences so the rest of the app never
/// touches the platform API directly. All built-in games, favorites,
/// high scores and settings are persisted here — everything works
/// fully offline.
class LocalStorageService {
  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Clears the cached SharedPreferences instance so the next [init]
  /// call re-fetches it. Only meaningful in tests, where each test
  /// sets fresh mock values via `SharedPreferences.setMockInitialValues`
  /// and needs the singleton to pick them up rather than reuse the
  /// previous test's cached instance.
  @visibleForTesting
  void resetForTesting() {
    _prefs = null;
  }

  SharedPreferences get _p {
    final p = _prefs;
    if (p == null) {
      throw StateError(
        'LocalStorageService.init() must be awaited before use.',
      );
    }
    return p;
  }

  // ---- Generic helpers -----------------------------------------------

  Future<void> setString(String key, String value) => _p.setString(key, value);
  String? getString(String key) => _p.getString(key);

  Future<void> setInt(String key, int value) => _p.setInt(key, value);
  int? getInt(String key) => _p.getInt(key);

  Future<void> setBool(String key, bool value) => _p.setBool(key, value);
  bool? getBool(String key) => _p.getBool(key);

  Future<void> setStringList(String key, List<String> value) =>
      _p.setStringList(key, value);
  List<String> getStringList(String key) => _p.getStringList(key) ?? [];

  Future<void> setJson(String key, Map<String, dynamic> value) =>
      _p.setString(key, jsonEncode(value));

  Map<String, dynamic>? getJson(String key) {
    final raw = _p.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> remove(String key) => _p.remove(key);

  Future<void> clearAll() => _p.clear();
}
