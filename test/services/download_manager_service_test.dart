import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gamebox/services/local_storage_service.dart';
import 'package:gamebox/services/download_manager_service.dart';
import 'package:gamebox/models/game_package.dart';

Future<LocalStorageService> freshStorage() async {
  SharedPreferences.setMockInitialValues({});
  final storage = LocalStorageService.instance;
  storage.resetForTesting();
  await storage.init();
  return storage;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadManagerService', () {
    test('the demo catalog has 3 downloadable games, none installed initially', () async {
      final storage = await freshStorage();
      final manager = DownloadManagerService(storage);

      expect(manager.catalog.length, 3);
      expect(manager.installedPackages, isEmpty);
      expect(manager.availablePackages.length, 3);
    });

    test('publishPackage adds a custom package and marks it installed immediately', () async {
      final storage = await freshStorage();
      final manager = DownloadManagerService(storage);

      const pkg = GamePackage(
        id: 'test_pack',
        name: 'Test Pack',
        category: 'Brain',
        description: 'A test package',
        rating: 4.0,
        sizeMB: 1.0,
        engineKey: 'word_scramble',
        isCustom: true,
      );
      await manager.publishPackage(pkg);

      expect(manager.isInstalled('test_pack'), isTrue);
      expect(manager.customPackages.map((p) => p.id), contains('test_pack'));
      expect(manager.catalog.length, 4);
    });

    test('publishing a package with an existing id replaces the old one', () async {
      final storage = await freshStorage();
      final manager = DownloadManagerService(storage);

      const v1 = GamePackage(
        id: 'test_pack', name: 'V1', category: 'Brain', description: 'd',
        rating: 4.0, sizeMB: 1.0, engineKey: 'word_scramble', isCustom: true,
      );
      const v2 = GamePackage(
        id: 'test_pack', name: 'V2', category: 'Brain', description: 'd',
        rating: 4.0, sizeMB: 1.0, engineKey: 'word_scramble', isCustom: true, version: '2.0.0',
      );
      await manager.publishPackage(v1);
      await manager.publishPackage(v2);

      expect(manager.customPackages.length, 1);
      expect(manager.customPackages.first.name, 'V2');
    });

    test('removePublishedPackage uninstalls and removes it from the catalog', () async {
      final storage = await freshStorage();
      final manager = DownloadManagerService(storage);

      const pkg = GamePackage(
        id: 'test_pack', name: 'Test Pack', category: 'Brain', description: 'd',
        rating: 4.0, sizeMB: 1.0, engineKey: 'word_scramble', isCustom: true,
      );
      await manager.publishPackage(pkg);
      await manager.removePublishedPackage('test_pack');

      expect(manager.isInstalled('test_pack'), isFalse);
      expect(manager.catalog.any((p) => p.id == 'test_pack'), isFalse);
      expect(manager.catalog.length, 3);
    });

    test('installed state persists across a new service instance reading the same storage', () async {
      final storage = await freshStorage();
      final managerA = DownloadManagerService(storage);
      const pkg = GamePackage(
        id: 'test_pack', name: 'Test Pack', category: 'Brain', description: 'd',
        rating: 4.0, sizeMB: 1.0, engineKey: 'word_scramble', isCustom: true,
      );
      await managerA.publishPackage(pkg);

      final managerB = DownloadManagerService(storage);
      expect(managerB.isInstalled('test_pack'), isTrue);
    });
  });
}
