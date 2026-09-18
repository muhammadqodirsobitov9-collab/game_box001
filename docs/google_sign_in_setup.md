# Google Sign-In setup

The app's Dart code (`lib/services/auth_service.dart`) is complete and
real — it calls Google's actual OAuth flow via the official
`google_sign_in` package. What it needs from you is an OAuth client
registered under **your own** Google account, because that
registration is tied to identity that only you have: your app's real
package name / bundle ID, and the SHA-1 fingerprint of the certificate
you'll sign the app with. There is no way to complete this step on
your behalf.

Until you complete this, tapping "Sign in with Google" in the Profile
screen will fail — that's Google's servers correctly rejecting an
unregistered app, not a bug.

## Option A: via Firebase (recommended, fewer manual steps)

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
   and create a project (or use an existing one).
2. Add an Android app to the project:
   - Package name must match `applicationId` in
     `android/app/build.gradle` after you run `flutter create .`
     (defaults to something like `com.example.gamebox` — change it to
     your own before doing this step, in both places).
   - Generate your app's signing SHA-1
     (`cd android && ./gradlew signingReport`, or
     `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
     for a debug build) and add it in the Firebase Android app
     settings.
   - Download `google-services.json` and place it at
     `android/app/google-services.json`.
   - In `android/build.gradle`, add to the `dependencies` block:
     `classpath 'com.google.gms:google-services:4.4.2'`
   - In `android/app/build.gradle`, add at the very bottom:
     `apply plugin: 'com.google.gms.google-services'`
3. Add an iOS app to the same Firebase project:
   - Bundle ID must match the one in `ios/Runner.xcodeproj`.
   - Download `GoogleService-Info.plist` and add it to
     `ios/Runner/` (drag into Xcode so it's included in the build).
   - Open `ios/Runner/Info.plist` and add a URL scheme using the
     `REVERSED_CLIENT_ID` value found inside
     `GoogleService-Info.plist`:
     ```xml
     <key>CFBundleURLTypes</key>
     <array>
       <dict>
         <key>CFBundleURLSchemes</key>
         <array>
           <string>PASTE_YOUR_REVERSED_CLIENT_ID_HERE</string>
         </array>
       </dict>
     </array>
     ```
4. `flutter clean && flutter pub get && flutter run`.

## Option B: via Google Cloud Console directly (no Firebase)

1. Go to [console.cloud.google.com](https://console.cloud.google.com) →
   APIs & Services → Credentials.
2. Create an OAuth 2.0 Client ID of type **Android**, entering your
   package name and SHA-1 (same values as Option A step 2).
3. Create a second OAuth 2.0 Client ID of type **iOS**, entering your
   bundle ID.
4. For iOS, you still need the URL scheme in `Info.plist` — use the
   iOS client ID's "reversed" form (reverse the dot-separated parts of
   the client ID and prefix with nothing else needed), or pass it
   explicitly:
   ```dart
   // in auth_service.dart, replace the GoogleSignIn() constructor with:
   GoogleSignIn(scopes: ['email'], clientId: 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com')
   ```
5. No `google-services.json` / Gradle plugin needed for Android with
   this option — the OAuth client registration alone is enough.

## Testing it worked

Run the app, go to Profile, tap "Sign in with Google". You should see
Google's real account picker. If you instead see an immediate error:

- **Android `ApiException: 10`** — the SHA-1 you registered doesn't
  match the certificate that actually signed the APK (a very common
  mismatch between debug and release keystores — make sure you
  registered the SHA-1 for the same keystore you're testing with).
- **iOS silently does nothing** — check the URL scheme in `Info.plist`
  matches exactly.

## What this feature does and doesn't do

- It's used only to show the signed-in Google account's name, email,
  and photo on the Profile screen, and to pre-fill the leaderboard
  display name.
- It does **not** gate any gameplay — every game, and every other
  feature, works fully offline whether or not the player ever signs
  in.
- It does **not** send anything to a GameBox server, because GameBox
  doesn't have one. Google's own servers handle the OAuth exchange;
  GameBox only receives the basic profile fields Google returns
  (name, email, photo URL) and stores them in memory for the current
  session (not persisted beyond what `google_sign_in`'s own silent
  sign-in already handles).
