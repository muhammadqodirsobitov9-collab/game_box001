/// Core data model for a single game in the GameBox catalog.
///
/// This model is intentionally flat and JSON-friendly so that both
/// built-in games and downloadable/admin-published game packages can
/// be represented the same way throughout the UI layer.
class GameModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final double rating;
  final String sizeLabel;
  final bool isNew;
  final bool isPopular;
  final bool offlineSupported;

  /// Identifier used to look up the actual playable widget for this
  /// game inside [GameRegistry]. Keeping this separate from [id]
  /// makes it possible to add downloadable games later without
  /// touching the routing logic for built-in games.
  final String engineKey;

  /// Optional content data for engines that support customization
  /// (for example a custom word list for the Word Scramble engine).
  /// Populated when this game came from an Admin Panel ZIP import;
  /// null for ordinary built-in/downloaded games, in which case the
  /// engine falls back to its own defaults.
  final Map<String, dynamic>? customData;

  const GameModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.rating,
    required this.sizeLabel,
    required this.engineKey,
    this.isNew = false,
    this.isPopular = false,
    this.offlineSupported = true,
    this.customData,
  });

  GameModel copyWith({
    bool? isNew,
    bool? isPopular,
  }) {
    return GameModel(
      id: id,
      name: name,
      category: category,
      description: description,
      rating: rating,
      sizeLabel: sizeLabel,
      engineKey: engineKey,
      isNew: isNew ?? this.isNew,
      isPopular: isPopular ?? this.isPopular,
      offlineSupported: offlineSupported,
      customData: customData,
    );
  }

  factory GameModel.fromJson(Map<String, dynamic> json) => GameModel(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        description: json['description'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        sizeLabel: json['sizeLabel'] as String? ?? '—',
        engineKey: json['engineKey'] as String,
        isNew: json['isNew'] as bool? ?? false,
        isPopular: json['isPopular'] as bool? ?? false,
        offlineSupported: json['offlineSupported'] as bool? ?? true,
        customData: (json['customData'] as Map?)?.cast<String, dynamic>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'rating': rating,
        'sizeLabel': sizeLabel,
        'engineKey': engineKey,
        'isNew': isNew,
        'isPopular': isPopular,
        'offlineSupported': offlineSupported,
        if (customData != null) 'customData': customData,
      };
}
