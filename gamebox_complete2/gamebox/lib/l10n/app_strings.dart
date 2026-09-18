import 'package:flutter/foundation.dart';
import '../services/local_storage_service.dart';

enum AppLanguage { uz, ru, en }

/// Lightweight in-app translation layer.
///
/// The spec calls for Uzbek/Russian/English support. Rather than pull
/// in the full `flutter_localizations` + `.arb` codegen pipeline for
/// three languages and a still-small string set, this uses a simple
/// key -> per-language map. It's trivial to migrate to `intl` later
/// once the string count grows into the hundreds — nothing in the UI
/// layer needs to change, since screens only ever call `t(context, key)`.
class AppStrings extends ChangeNotifier {
  static const _storageKey = 'app_language';

  AppLanguage _language;
  final LocalStorageService _storage;

  AppStrings(this._storage)
      : _language = _fromCode(_storage.getString(_storageKey)) ?? AppLanguage.en;

  AppLanguage get language => _language;

  Future<void> setLanguage(AppLanguage lang) async {
    _language = lang;
    await _storage.setString(_storageKey, lang.name);
    notifyListeners();
  }

  static AppLanguage? _fromCode(String? code) {
    if (code == null) return null;
    return AppLanguage.values.where((l) => l.name == code).firstOrNull;
  }

  String t(String key) {
    return _values[key]?[_language] ?? _values[key]?[AppLanguage.en] ?? key;
  }

  static final Map<String, Map<AppLanguage, String>> _values = {
    'home': {AppLanguage.en: 'Home', AppLanguage.ru: 'Главная', AppLanguage.uz: 'Bosh sahifa'},
    'games': {AppLanguage.en: 'Games', AppLanguage.ru: 'Игры', AppLanguage.uz: "O'yinlar"},
    'downloads': {AppLanguage.en: 'Downloads', AppLanguage.ru: 'Загрузки', AppLanguage.uz: 'Yuklamalar'},
    'favorites': {AppLanguage.en: 'Favorites', AppLanguage.ru: 'Избранное', AppLanguage.uz: 'Sevimlilar'},
    'profile': {AppLanguage.en: 'Profile', AppLanguage.ru: 'Профиль', AppLanguage.uz: 'Profil'},
    'settings': {AppLanguage.en: 'Settings', AppLanguage.ru: 'Настройки', AppLanguage.uz: 'Sozlamalar'},
    'popular': {AppLanguage.en: 'Popular Games', AppLanguage.ru: 'Популярные игры', AppLanguage.uz: 'Mashhur oʻyinlar'},
    'new_games': {AppLanguage.en: 'New Games', AppLanguage.ru: 'Новые игры', AppLanguage.uz: 'Yangi oʻyinlar'},
    'search_hint': {AppLanguage.en: 'Search games…', AppLanguage.ru: 'Поиск игр…', AppLanguage.uz: "O'yin qidirish…"},
    'play': {AppLanguage.en: 'Play', AppLanguage.ru: 'Играть', AppLanguage.uz: "O'ynash"},
    'dark_mode': {AppLanguage.en: 'Dark mode', AppLanguage.ru: 'Тёмная тема', AppLanguage.uz: 'Tungi rejim'},
    'language': {AppLanguage.en: 'Language', AppLanguage.ru: 'Язык', AppLanguage.uz: 'Til'},
    'no_favorites': {
      AppLanguage.en: 'No favorites yet — tap the heart on any game to add it here.',
      AppLanguage.ru: 'Пока нет избранного — нажмите на сердечко у любой игры.',
      AppLanguage.uz: 'Hali sevimlilar yoʻq — istalgan oʻyindagi yurak belgisini bosing.',
    },
    'high_score': {AppLanguage.en: 'High score', AppLanguage.ru: 'Рекорд', AppLanguage.uz: 'Rekord'},
    'game_over': {AppLanguage.en: 'Game Over', AppLanguage.ru: 'Игра окончена', AppLanguage.uz: "O'yin tugadi"},
    'restart': {AppLanguage.en: 'Restart', AppLanguage.ru: 'Заново', AppLanguage.uz: 'Qayta boshlash'},
    'score': {AppLanguage.en: 'Score', AppLanguage.ru: 'Счёт', AppLanguage.uz: 'Ball'},
    'welcome_title': {
      AppLanguage.en: 'Welcome to GameBox',
      AppLanguage.ru: 'Добро пожаловать в GameBox',
      AppLanguage.uz: 'GameBox-ga xush kelibsiz',
    },
    'welcome_subtitle': {
      AppLanguage.en: 'Original mini-games, fully offline.',
      AppLanguage.ru: 'Оригинальные мини-игры, полностью офлайн.',
      AppLanguage.uz: "Original mini-o'yinlar, toʻliq oflayn.",
    },
    'get_started': {AppLanguage.en: 'Get Started', AppLanguage.ru: 'Начать', AppLanguage.uz: 'Boshlash'},
  };
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
