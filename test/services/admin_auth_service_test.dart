import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gamebox/services/local_storage_service.dart';
import 'package:gamebox/services/admin_auth_service.dart';

Future<LocalStorageService> freshStorage() async {
  SharedPreferences.setMockInitialValues({});
  final storage = LocalStorageService.instance;
  storage.resetForTesting();
  await storage.init();
  return storage;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminAuthService', () {
    test('has no PIN set initially', () async {
      final storage = await freshStorage();
      final auth = AdminAuthService(storage);
      expect(auth.hasPin, isFalse);
    });

    test('setPin then verifyPin succeeds with the correct PIN', () async {
      final storage = await freshStorage();
      final auth = AdminAuthService(storage);

      await auth.setPin('4242');
      expect(auth.hasPin, isTrue);
      expect(auth.verifyPin('4242'), isTrue);
    });

    test('verifyPin fails with an incorrect PIN', () async {
      final storage = await freshStorage();
      final auth = AdminAuthService(storage);

      await auth.setPin('4242');
      expect(auth.verifyPin('0000'), isFalse);
    });

    test('the PIN is never stored in plaintext', () async {
      final storage = await freshStorage();
      final auth = AdminAuthService(storage);

      await auth.setPin('4242');
      final rawStorageDump = storage.getString('admin_pin_hash');
      expect(rawStorageDump, isNotNull);
      expect(rawStorageDump, isNot(contains('4242')));
    });

    test('locks out after 5 failed attempts', () async {
      final storage = await freshStorage();
      final auth = AdminAuthService(storage);
      await auth.setPin('4242');

      for (var i = 0; i < AdminAuthService.maxAttempts; i++) {
        auth.verifyPin('wrong');
      }

      expect(auth.isLockedOut, isTrue);
      // Even the correct PIN is rejected while locked out.
      expect(auth.verifyPin('4242'), isFalse);
    });

    test('a correct guess resets the failed-attempt counter', () async {
      final storage = await freshStorage();
      final auth = AdminAuthService(storage);
      await auth.setPin('4242');

      auth.verifyPin('wrong');
      auth.verifyPin('wrong');
      expect(auth.verifyPin('4242'), isTrue);
      expect(auth.attemptsRemaining, AdminAuthService.maxAttempts);
    });

    test('changing the PIN invalidates the old one', () async {
      final storage = await freshStorage();
      final auth = AdminAuthService(storage);

      await auth.setPin('4242');
      await auth.setPin('9999');

      expect(auth.verifyPin('4242'), isFalse);
      expect(auth.verifyPin('9999'), isTrue);
    });
  });
}
