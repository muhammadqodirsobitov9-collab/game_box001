import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'local_storage_service.dart';

/// Real (device-local) admin authentication: a PIN the admin sets
/// themselves on first use, stored as a salted SHA-256 hash rather
/// than in plaintext, with a short lockout after repeated failures.
///
/// ## Honesty note
/// This is still **local-device security**, not a real multi-user
/// auth system — there is no server, no account, no password reset
/// email, because this app has no backend (consistent with the rest
/// of GameBox's offline-first design). What changed from the earlier
/// hardcoded "1234" demo gate is real: the PIN is chosen by whoever
/// sets up the app, it's never stored or compared as plaintext, and
/// repeated wrong guesses are throttled. That's meaningfully better
/// than a shared hardcoded secret, even though it doesn't turn this
/// into server-verified authentication.
class AdminAuthService {
  static const _hashKey = 'admin_pin_hash';
  static const _saltKey = 'admin_pin_salt';
  static const maxAttempts = 5;
  static const lockoutSeconds = 30;

  final LocalStorageService _storage;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  AdminAuthService(this._storage);

  bool get hasPin => _storage.getString(_hashKey) != null;

  bool get isLockedOut => _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  int get lockoutSecondsRemaining {
    if (!isLockedOut) return 0;
    return _lockedUntil!.difference(DateTime.now()).inSeconds + 1;
  }

  String _hash(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  String _generateSalt() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return sha256.convert(utf8.encode('$now-gamebox-salt')).toString().substring(0, 16);
  }

  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    await _storage.setString(_saltKey, salt);
    await _storage.setString(_hashKey, _hash(pin, salt));
    _failedAttempts = 0;
    _lockedUntil = null;
  }

  /// Verifies [pin] against the stored hash. Returns true on success.
  /// Wrong guesses count toward a lockout; a correct guess resets the
  /// counter immediately.
  bool verifyPin(String pin) {
    if (isLockedOut) return false;
    final salt = _storage.getString(_saltKey);
    final storedHash = _storage.getString(_hashKey);
    if (salt == null || storedHash == null) return false;

    final matches = _hash(pin, salt) == storedHash;
    if (matches) {
      _failedAttempts = 0;
      _lockedUntil = null;
      return true;
    }

    _failedAttempts++;
    if (_failedAttempts >= maxAttempts) {
      _lockedUntil = DateTime.now().add(const Duration(seconds: lockoutSeconds));
      _failedAttempts = 0;
    }
    return false;
  }

  int get attemptsRemaining => maxAttempts - _failedAttempts;
}
