import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../models/game_package.dart';
import 'download_manager_service.dart';

/// Thrown when a ZIP fails validation, with a human-readable reason
/// shown directly in the Admin Panel's import dialog.
class PackageImportException implements Exception {
  final String message;
  PackageImportException(this.message);
  @override
  String toString() => message;
}

/// ZIP-package import for the Admin Panel. PIN gating lives in
/// AdminAuthService — this class handles validating and publishing
/// a package once the admin is already authenticated.
///
/// Important technical honesty note: Flutter apps compiled ahead-of-time
/// (which is how every real Android/iOS build works) cannot load and
/// execute arbitrary new Dart code at runtime — there's no safe,
/// supported way to ship a brand new game *engine* inside a ZIP and
/// have the app run it without a full rebuild. So "ZIP import" here
/// does the thing that's actually possible and still genuinely useful:
/// it lets an admin publish a new catalog *listing* that reuses one of
/// the engines already compiled into the app, optionally with custom
/// content data (for example a different word list for the Word
/// Scramble engine, see `words.json` below). That's a real, working
/// content-publishing pipeline — re-skinned/re-themed instances of
/// existing games — not a simulated one.
///
/// ## Expected ZIP layout
/// ```
/// package.zip
///   manifest.json   (required)
///   words.json      (optional — only used when engineKey is "word_scramble")
/// ```
///
/// ## manifest.json fields
/// - id (String, required, unique)
/// - name (String, required)
/// - category (String, required)
/// - description (String, required)
/// - rating (number, optional, default 4.0)
/// - sizeMB (number, optional, default 1.0)
/// - engineKey (String, required — must be one of [knownEngineKeys])
/// - version (String, optional, default "1.0.0")
class AdminService {
  AdminService._();

  // PIN gating now lives in AdminAuthService (a user-set, hashed PIN
  // with lockout protection) rather than a hardcoded demo constant.

  /// Engines that are safe to re-list from a ZIP without risking a
  /// broken "This game is not implemented yet" screen. Kept as an
  /// explicit allow-list (rather than reflecting over GameRegistry)
  /// so a manifest typo fails import instead of silently pointing at
  /// nothing.
  static const knownEngineKeys = [
    'snake', 'tic_tac_toe', 'runner', 'memory', 'puzzle_2048',
    'whack_a_mole', 'reaction_time', 'simon_says', 'rock_paper_scissors',
    'number_guess', 'minesweeper', 'connect_four', 'sliding_puzzle',
    'word_scramble', 'higher_lower', 'brick_breaker',
    'mini_sudoku', 'match_three', 'typing_speed',
  ];

  /// Parses ZIP bytes into a [GamePackage] and publishes it through
  /// [manager]. Throws [PackageImportException] with a user-facing
  /// message on any validation failure.
  static Future<GamePackage> importAndPublish(
    Uint8List zipBytes,
    DownloadManagerService manager,
  ) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (_) {
      throw PackageImportException('This file is not a valid ZIP archive.');
    }

    final manifestFile = archive.files.firstWhere(
      (f) => f.name == 'manifest.json' || f.name.endsWith('/manifest.json'),
      orElse: () => throw PackageImportException('manifest.json not found in the ZIP.'),
    );

    late Map<String, dynamic> manifest;
    try {
      final content = utf8.decode(manifestFile.content as List<int>);
      manifest = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      throw PackageImportException('manifest.json is not valid JSON.');
    }

    for (final field in ['id', 'name', 'category', 'description', 'engineKey']) {
      if (manifest[field] == null || (manifest[field] as String).trim().isEmpty) {
        throw PackageImportException('manifest.json is missing required field "$field".');
      }
    }

    final engineKey = manifest['engineKey'] as String;
    if (!knownEngineKeys.contains(engineKey)) {
      throw PackageImportException(
        'Unknown engineKey "$engineKey". Must be one of: ${knownEngineKeys.join(', ')}',
      );
    }

    final id = manifest['id'] as String;
    if (manager.catalog.any((p) => p.id == id) &&
        !manager.customPackages.any((p) => p.id == id)) {
      throw PackageImportException('A built-in package with id "$id" already exists.');
    }

    Map<String, dynamic>? customData;
    if (engineKey == 'word_scramble') {
      final wordsFile = archive.files.where(
        (f) => f.name == 'words.json' || f.name.endsWith('/words.json'),
      );
      if (wordsFile.isNotEmpty) {
        try {
          final content = utf8.decode(wordsFile.first.content as List<int>);
          final words = (jsonDecode(content) as List).cast<String>();
          if (words.isEmpty) {
            throw PackageImportException('words.json must contain at least one word.');
          }
          customData = {'words': words.map((w) => w.toUpperCase()).toList()};
        } on PackageImportException {
          rethrow;
        } catch (_) {
          throw PackageImportException('words.json is not a valid JSON array of strings.');
        }
      }
    }

    final package = GamePackage(
      id: id,
      name: manifest['name'] as String,
      category: manifest['category'] as String,
      description: manifest['description'] as String,
      rating: (manifest['rating'] as num?)?.toDouble() ?? 4.0,
      sizeMB: (manifest['sizeMB'] as num?)?.toDouble() ?? 1.0,
      engineKey: engineKey,
      version: manifest['version'] as String? ?? '1.0.0',
      isCustom: true,
      customData: customData,
    );

    await manager.publishPackage(package);
    return package;
  }
}
