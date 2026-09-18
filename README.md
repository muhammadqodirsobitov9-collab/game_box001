# GameBox — Parts 1-10 (Foundation + Progression + 50 Games + Download Manager + Admin Panel + Sound/Haptics + Leaderboards + Icon/Splash + Auth/Tests/Store + Google Sign-In)

A real, working Flutter starting point for the full GameBox spec:
navigation, architecture, offline storage, theming, i18n, a full
XP/level/coins/achievements progression system, and the full 50
mini-games from the original spec, plus a
working Download Manager, and an Admin Panel with ZIP-based package
publishing.

## What's implemented so far

**Part 1 — Foundation**: bottom nav + drawer, `GameModel`/`GameRepository`/
`LocalStorageService`/`FavoritesService`/`StatisticsService`, offline
`shared_preferences` storage, dark/light theme, EN/RU/UZ i18n, onboarding.

**Part 2 — Progression**: `ProgressionService` (XP, levels, coins, 8
achievements) and `GameResultHandler`, the single place every game
reports through. Profile screen + live coin/level badge in the app bar.

**Part 3 — 47 built-in games**, across Arcade / Puzzle / Brain / Casual:

*Arcade:* Snake, Endless Runner, Whack-a-Mole, Brick Breaker, Fruit
Slice, Flappy Block, Pong, Tetris Lite, Air Hockey, Target Shooter,
Alien Shooter, Basketball Shootout, Rhythm Tap

*Puzzle:* Tic-Tac-Toe, 2048, Minesweeper, Connect Four, 15 Puzzle,
Battleship, Maze Escape, Sokoban Mini, Sudoku, Bubble Pop, Checkers,
Peg Solitaire

*Brain:* Memory Puzzle, Reaction Time, Simon Says, Number Guess, Word
Scramble, Hangman, Speed Math, Quiz Trivia, Anagram Hunter, Odd One
Out, Reflex Sequence, Wordle, Tower of Hanoi

*Casual:* Rock Paper Scissors, Higher or Lower, Dice Duel, Color Match,
Tug of War, Coin Flip Streak, Balloon Inflate, Blackjack, Darts

Plus 3 **downloadable** games (Part 4): Mini Sudoku, Match Three,
Typing Speed — for **50 games total**.

**Part 4 — Download Manager**: `GamePackage` + `DownloadManagerService`
with a simulated download queue (progress/pause/resume/cancel/uninstall,
persisted). 3 downloadable games: Mini Sudoku, Match Three, Typing Speed.
Installed packages behave exactly like built-in games everywhere.

**Part 5 — Admin Panel + ZIP import**
- Drawer → Admin Panel, gated by a demo PIN (**1234** — this is a UI
  gate, not real auth; see the note in `admin_service.dart`).
- Dashboard: total games, total plays, custom-package count, unlocked
  achievements.
- **Import ZIP package**: pick a `.zip` from the device, and
  `AdminService` validates and publishes it as a new catalog entry,
  installed immediately.
- **Important technical honesty note**: a compiled Flutter app cannot
  load and run brand-new Dart code from a ZIP at runtime — there is no
  safe way to ship a truly new game *engine* without rebuilding the
  app. So ZIP import does the real, working version of this: it
  publishes a new catalog *listing* backed by one of the engines
  already compiled into the app, optionally with custom content data.
  Word Scramble is wired up as the concrete example — a ZIP can supply
  its own `words.json` and the published listing plays with those
  words instead of the defaults.
- A ready-to-try example is included: `samples/uzbek_word_pack.zip`
  (manifest + a small Uzbek word list). Pick Admin Panel → Import ZIP
  package → select that file to see it appear as an installed game
  immediately.

### ZIP package format
```
package.zip
  manifest.json   (required)
  words.json      (optional — only read when engineKey is "word_scramble")
```
`manifest.json` fields: `id`, `name`, `category`, `description`
(required strings), `engineKey` (required, must be one of the
built-in engine keys — see `AdminService.knownEngineKeys`), `rating`
and `sizeMB` (optional numbers), `version` (optional string).

**Part 6 — Real sound & haptic feedback**
- `SoundService`: wraps Flutter's own `SystemSound` and
  `HapticFeedback` APIs — no audio asset files, no new dependencies.
  This was a deliberate choice: sourcing licensed sound-effect files
  isn't something that could be done safely/legally in this build
  environment, but system click sounds and real device haptics are
  genuine feedback, not a mock.
- Wired into `GameResultHandler`, the same shared checkpoint every
  game already reports through — so a light success buzz on a new
  high score and a stronger one on an achievement unlock work across
  **all 50 games** without editing each game file.
- Settings screen: toggling Sound/Vibration takes effect immediately
  (no restart needed), plus a "Test sound & vibration" row to try it.
- Bottom nav tab switches get a subtle tap click too.

**Part 7 — Leaderboards**
- `LeaderboardService` + a Leaderboard screen reachable from any
  game's detail page.
- **Important honesty note**: a genuine global leaderboard needs a
  server to store and serve every player's scores — this app has none
  (offline-first by design). So "other players" here are a
  deterministic simulated field (seeded per game, not random noise
  each time you open it), clearly labeled in the UI as a demo
  leaderboard. Your own score is real, pulled from `StatisticsService`.
- You can set a display name for the leaderboard (persisted locally).
- Swapping in a real backend later only means replacing
  `LeaderboardService._simulatedScoresFor()` with a network call — no
  screen needs to change.

**Part 8 — App icon & splash screen**
- A real icon (not a placeholder): a neon-blue outlined gamepad glyph
  with the "GameBox" wordmark on a dark navy gradient background,
  matching the design you provided. Generated as artwork under
  `assets/icon/` — `app_icon.png` (full icon), `app_icon_foreground.png`
  (transparent, for Android's adaptive icon layer), `splash_logo.png`
  (splash mark).
- `flutter_launcher_icons` and `flutter_native_splash` are configured
  in `pubspec.yaml` to generate every platform size from that one
  source image — including a proper Android adaptive icon (glyph +
  solid `#0A0E23` navy background layer) and matching splash screen.
- These are dev-tool generators, not runtime code: after
  `flutter pub get`, run
  `dart run flutter_launcher_icons` and
  `dart run flutter_native_splash:create`
  once to actually write the platform icon/splash files into
  `android/` and `ios/` (generated after you run `flutter create .`,
  per the instructions below).

**Part 9 — Real admin auth, tests, and store metadata**
- `AdminAuthService`: replaces the old hardcoded "1234" demo PIN with
  one the admin sets themselves on first use, stored as a salted
  SHA-256 hash (never plaintext), with lockout after 5 failed
  attempts. A "Change PIN" option lives in the Admin dashboard.
  Still local-device security, not server-verified multi-user auth —
  this app has no backend — but a real improvement over a shared
  hardcoded secret.
- `test/`: unit tests for `ProgressionService` (XP/leveling/
  achievements), `GameRepository` (all 47 built-in games present,
  unique ids, every one has a working `GameRegistry` entry),
  `AdminAuthService` (PIN setup/verify/lockout), and
  `DownloadManagerService` (publish/remove/persistence), plus a
  widget smoke test for the app's onboarding → main navigation flow.
  Run with `flutter test`.
- `store/`: `listing.md` (store description/keywords copy),
  `privacy_policy.md` (accurate to this app's offline-only, no-ads,
  no-analytics architecture), `screenshots_checklist.md` (what to
  capture once you can run the app — see the honesty note inside:
  no Flutter SDK here means no real screenshots could be generated),
  and `release_notes.md`.

**Part 10 — Google Sign-In**
- `AuthService` wraps the real `google_sign_in` package — genuine
  Google OAuth, not a mock. Profile screen shows a "Sign in with
  Google" card; once signed in, it shows the real account's name,
  email, and photo, and offers "Sign out".
- **Important honesty note**: Google Sign-In requires an OAuth client
  registered under *your own* Google Cloud/Firebase account, tied to
  your app's real package name and signing certificate SHA-1 — none
  of which exist yet for an unbuilt app, and none of which I can
  register on your behalf. Until you complete that one-time setup,
  tapping "Sign in with Google" will fail with a real error from
  Google's servers (not a bug in this code). Full step-by-step
  instructions: `docs/google_sign_in_setup.md`.
- Sign-in is entirely optional and additive: no game or feature is
  gated behind it. It only personalizes the Profile screen and
  pre-fills your leaderboard display name (without overwriting a name
  you already set yourself).

## Not yet built

- A real backend (today's "remote catalog" and "downloads" are both
  simulated/local, by design, since this is an offline-first app)
- Real screenshots (need a running build — see store/screenshots_checklist.md)
- android/ios platform folders (generate locally — see "Running it" below)

## Running it

No Flutter SDK was available in the authoring environment, so the
platform folders (`android/`, `ios/`) aren't included yet — generate
them locally with:

```bash
flutter create . --platforms=android
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter run
```

`flutter create .` scaffolds `android/` around the existing `lib/`
and `pubspec.yaml` without overwriting them. Then `flutter build apk`
produces an installable APK. `flutter pub get` will fetch the new
dependencies (`archive`, `file_picker` for ZIP import;
`flutter_launcher_icons`, `flutter_native_splash` for the app icon and
splash screen; `crypto` for admin PIN hashing; `google_sign_in` for
Google sign-in — see `docs/google_sign_in_setup.md` before that one
will actually work). The two `dart run` commands only need to be
re-run if you change the source artwork under `assets/icon/`.

## Project layout

```
lib/
  main.dart
  theme/app_theme.dart
  l10n/app_strings.dart
  models/
    game_model.dart
    game_package.dart
  services/
    local_storage_service.dart
    favorites_service.dart
    statistics_service.dart
    progression_service.dart
    game_result_handler.dart
    game_repository.dart
    download_manager_service.dart
    admin_service.dart
    theme_controller.dart
  screens/
    onboarding_screen.dart
    home_screen.dart
    games_screen.dart
    favorites_screen.dart
    downloads_screen.dart
    profile_screen.dart
    settings_screen.dart
    contact_screen.dart
    game_detail_screen.dart
    admin_panel_screen.dart
  widgets/
    main_scaffold.dart
    game_card.dart
  games/
    game_registry.dart
    snake_game.dart, tic_tac_toe_game.dart, runner_game.dart,
    memory_game.dart, puzzle_2048_game.dart, whack_a_mole_game.dart,
    reaction_time_game.dart, simon_says_game.dart,
    rock_paper_scissors_game.dart, number_guess_game.dart,
    minesweeper_game.dart, connect_four_game.dart,
    sliding_puzzle_game.dart, word_scramble_game.dart,
    higher_lower_game.dart, brick_breaker_game.dart,
    dice_duel_game.dart, fruit_slice_game.dart, flappy_block_game.dart,
    pong_game.dart, hangman_game.dart, speed_math_game.dart,
    quiz_trivia_game.dart, battleship_game.dart, maze_escape_game.dart,
    color_match_game.dart, tetris_lite_game.dart, sokoban_mini_game.dart,
    sudoku_classic_game.dart, target_shooter_game.dart, tug_of_war_game.dart,
    coin_flip_streak_game.dart, anagram_hunter_game.dart, odd_one_out_game.dart,
    bubble_pop_match_game.dart, balloon_inflate_game.dart, air_hockey_game.dart,
    reflex_sequence_game.dart, wordle_game.dart, alien_shooter_game.dart,
    checkers_game.dart, tower_of_hanoi_game.dart, peg_solitaire_game.dart,
    blackjack_game.dart, basketball_shootout_game.dart, rhythm_tap_game.dart,
    darts_game.dart,
    mini_sudoku_game.dart, match_three_game.dart, typing_speed_game.dart
samples/
  uzbek_word_pack.zip   (example Admin Panel import)
```

Adding a new **built-in** game: one file in `lib/games/`, one entry in
`GameRegistry`, one `GameModel` in `GameRepository`, one call to
`GameResultHandler.report(...)`.

Adding a new **downloadable** game: one file in `lib/games/`, one
entry in `GameRegistry`, one `GamePackage` in
`DownloadManagerService._staticCatalog`.

Publishing a **content pack** for an existing engine: no code at all —
just a ZIP with `manifest.json` (+ `words.json` for Word Scramble),
imported through the Admin Panel.
