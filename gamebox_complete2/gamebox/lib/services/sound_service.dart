import 'package:flutter/services.dart';
import 'local_storage_service.dart';

/// Real (not simulated) sound + haptic feedback, built entirely on
/// Flutter's own `SystemSound` and `HapticFeedback` APIs — no audio
/// asset files and no new dependencies needed. This is a deliberate
/// choice: sourcing licensed sound-effect files isn't something this
/// environment can safely do, but system click sounds and haptics are
/// real device feedback, not a mock.
///
/// Every call checks the same `sound_enabled` / `vibration_enabled`
/// flags the Settings screen already writes to, so muting either one
/// there immediately silences this service — no separate wiring
/// needed per game.
///
/// Because every built-in and downloaded game reports through
/// `GameResultHandler`, wiring feedback in there (see
/// `game_result_handler.dart`) gives every one of the 50 games sound
/// + haptic feedback on achievement unlocks and new high scores
/// without editing each game file individually.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  bool _soundOn = true;
  bool _vibrationOn = true;

  void loadPreferences(LocalStorageService storage) {
    _soundOn = storage.getBool('sound_enabled') ?? true;
    _vibrationOn = storage.getBool('vibration_enabled') ?? true;
  }

  /// Short, neutral click — used for ordinary taps (nav switch, card
  /// press) where feedback should be present but unobtrusive.
  void tap() {
    if (_soundOn) SystemSound.play(SystemSoundType.click);
    if (_vibrationOn) HapticFeedback.selectionClick();
  }

  /// Positive feedback — a new high score, a correct answer, a puzzle
  /// solved.
  void success() {
    if (_soundOn) SystemSound.play(SystemSoundType.click);
    if (_vibrationOn) HapticFeedback.lightImpact();
  }

  /// Bigger positive feedback — an achievement unlock or level-up,
  /// which are rarer and worth a stronger nudge than a plain success.
  void celebrate() {
    if (_soundOn) SystemSound.play(SystemSoundType.click);
    if (_vibrationOn) HapticFeedback.mediumImpact();
  }

  /// Negative feedback — game over, wrong answer, a lost round.
  void fail() {
    if (_soundOn) SystemSound.play(SystemSoundType.alert);
    if (_vibrationOn) HapticFeedback.heavyImpact();
  }
}
