import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';

/// Reactive dark/light mode switch. Kept separate from
/// LocalStorageService (which isn't a ChangeNotifier) so screens can
/// watch it and rebuild immediately when the user flips the toggle.
class ThemeController extends ChangeNotifier {
  static const _key = 'dark_mode';

  final LocalStorageService _storage;
  bool _isDark;

  ThemeController(this._storage) : _isDark = _storage.getBool(_key) ?? true;

  bool get isDark => _isDark;

  Future<void> setDark(bool value) async {
    _isDark = value;
    await _storage.setBool(_key, value);
    notifyListeners();
  }
}
