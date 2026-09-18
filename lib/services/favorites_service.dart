import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';

/// Keeps track of which game ids the player has favorited.
/// Works fully offline — backed by [LocalStorageService].
class FavoritesService extends ChangeNotifier {
  static const _key = 'favorite_game_ids';

  final LocalStorageService _storage;
  final Set<String> _favoriteIds;

  FavoritesService(this._storage)
      : _favoriteIds = _storage.getStringList(_key).toSet();

  bool isFavorite(String gameId) => _favoriteIds.contains(gameId);

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  Future<void> toggle(String gameId) async {
    if (_favoriteIds.contains(gameId)) {
      _favoriteIds.remove(gameId);
    } else {
      _favoriteIds.add(gameId);
    }
    await _storage.setStringList(_key, _favoriteIds.toList());
    notifyListeners();
  }
}
