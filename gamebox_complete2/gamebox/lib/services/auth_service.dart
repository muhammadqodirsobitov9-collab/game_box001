import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Real Google Sign-In, using the official `google_sign_in` package —
/// this is genuine OAuth against Google's own servers, not a mock.
///
/// ## What you must set up yourself before this works
/// Google Sign-In requires an OAuth client registered to a real app
/// identity (package name + signing certificate for Android, bundle
/// ID for iOS) under **your own** Google Cloud / Firebase account.
/// That can't be done on your behalf — it requires your Google
/// account, your app's real package name, and your release signing
/// key's SHA-1 fingerprint. See the "Google Sign-In setup" section in
/// the README for the exact steps. Until that's done, `signIn()`
/// will fail with a `PlatformException` (`sign_in_failed` /
/// `ApiException: 10` on Android is the classic "OAuth client not
/// configured" error) — that's Google's servers rejecting the
/// request, not a bug in this code.
///
/// Sign-in here is **optional and additive**: nothing in GameBox is
/// gated behind it. A signed-in Google account is used only to
/// personalize the Profile screen and pre-fill a leaderboard display
/// name — all gameplay, progress, and offline features work
/// identically whether or not the player ever signs in.
class AuthService extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  GoogleSignInAccount? _user;
  bool _isSigningIn = false;
  String? _lastError;

  GoogleSignInAccount? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isSigningIn => _isSigningIn;
  String? get lastError => _lastError;

  /// Call once at app startup. Silently restores a previous session
  /// if the user already granted access and is still logged into
  /// Google on this device — no UI shown, no-op if not.
  Future<void> trySilentSignIn() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        _user = account;
        notifyListeners();
      }
    } catch (_) {
      // No prior session, or Google Sign-In isn't configured yet for
      // this platform — fail quietly, sign-in is optional.
    }
  }

  /// Shows the real Google account picker / consent screen.
  Future<bool> signIn() async {
    _isSigningIn = true;
    _lastError = null;
    notifyListeners();
    try {
      final account = await _googleSignIn.signIn();
      _user = account;
      _isSigningIn = false;
      if (account == null) {
        // User closed the picker without choosing an account.
        notifyListeners();
        return false;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _isSigningIn = false;
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _user = null;
    notifyListeners();
  }
}
