import 'game_model.dart';

/// Represents a game available from the downloadable catalog, as
/// opposed to a built-in [GameModel] that ships inside the app.
///
/// Kept as a separate type (rather than reusing GameModel directly)
/// because a package carries download-specific metadata (size in MB
/// for progress math, a version, and whether it was published locally
/// through the Admin Panel). `toGameModel()` bridges it into the same
/// shape the rest of the UI (GameCard, GameDetailScreen, GameRegistry)
/// already knows how to render, so no screen needs a separate "is
/// this downloaded?" branch — once installed, a package is just
/// another GameModel.
class GamePackage {
  final String id;
  final String name;
  final String category;
  final String description;
  final double rating;
  final double sizeMB;
  final String version;
  final String engineKey;

  /// True for packages published through the Admin Panel's ZIP
  /// import, as opposed to the hardcoded demo catalog. Purely
  /// informational — shown as a "Custom" badge in the Downloads
  /// screen — it doesn't change how the package behaves.
  final bool isCustom;

  /// Optional engine content (e.g. a custom word list). Carried
  /// straight through to the resulting GameModel.
  final Map<String, dynamic>? customData;

  const GamePackage({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.rating,
    required this.sizeMB,
    required this.engineKey,
    this.version = '1.0.0',
    this.isCustom = false,
    this.customData,
  });

  GameModel toGameModel({bool isNew = false}) => GameModel(
        id: id,
        name: name,
        category: category,
        description: description,
        rating: rating,
        sizeLabel: '${sizeMB.toStringAsFixed(1)} MB',
        engineKey: engineKey,
        isNew: isNew,
        customData: customData,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'rating': rating,
        'sizeMB': sizeMB,
        'version': version,
        'engineKey': engineKey,
        'isCustom': isCustom,
        if (customData != null) 'customData': customData,
      };

  factory GamePackage.fromJson(Map<String, dynamic> json) => GamePackage(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        description: json['description'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        sizeMB: (json['sizeMB'] as num?)?.toDouble() ?? 1.0,
        version: json['version'] as String? ?? '1.0.0',
        engineKey: json['engineKey'] as String,
        isCustom: json['isCustom'] as bool? ?? false,
        customData: (json['customData'] as Map?)?.cast<String, dynamic>(),
      );
}
