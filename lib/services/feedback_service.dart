import 'dart:async' show unawaited;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show HapticFeedback;

/// Every sound/haptic moment in the app (REDESIGN_1.3_PLAN.md §3).
enum Fx {
  mark,
  unmark,

  /// A swipe drag crosses the decide line (either way). Haptic only.
  detent,
  delete,
  keep,
  undo,

  /// Group "Delete n · Next".
  groupDone,

  /// Group "Keep all · Next".
  groupKeep,

  /// The OS delete prompt was confirmed.
  success,

  /// A lifetime milestone was crossed (played 0.9 s after [success]).
  milestone,

  /// The OS delete prompt was declined. Haptic only.
  declined,

  /// Tabs, toggles. Haptic only.
  tap,
}

/// Short UI sounds + haptics. A singleton like AdService.
///
/// Sounds use the iOS **ambient** session (obeys the silent switch, mixes
/// with music and never pauses it) and, on Android, the "UI sound" usage with
/// no audio focus, so Spotify keeps playing. A sound failing must never break
/// a flow — every platform call is wrapped.
class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  /// Set by AppProvider from the Settings toggles (both default on).
  bool soundsEnabled = true;
  bool hapticsEnabled = true;

  static const Map<Fx, String> _soundFiles = {
    Fx.mark: 'mark',
    Fx.unmark: 'unmark',
    Fx.delete: 'delete',
    Fx.keep: 'keep',
    Fx.undo: 'undo',
    Fx.groupDone: 'group_done',
    Fx.groupKeep: 'keep',
    Fx.success: 'success',
    Fx.milestone: 'milestone',
  };

  static const double _volume = 0.5;

  /// Drop a sound if another one started less than this long ago, so fast
  /// swiping doesn't stack a wall of noise. Haptics are never throttled.
  static const Duration _throttle = Duration(milliseconds: 50);

  final Map<String, AudioPlayer> _players = {};
  DateTime _lastSoundAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _initStarted = false;

  static final AudioContext _context = AudioContext(
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  /// Configure the audio session and preload one low-latency player per file.
  /// Safe to call more than once; failures just leave sounds off.
  Future<void> init() async {
    if (_initStarted) return;
    _initStarted = true;
    try {
      await AudioPlayer.global.setAudioContext(_context);
    } catch (e) {
      debugPrint('[Fx] audio context failed: $e');
    }
    for (final file in _soundFiles.values.toSet()) {
      try {
        final p = AudioPlayer(playerId: 'fx_$file');
        await p.setAudioContext(_context);
        await p.setPlayerMode(PlayerMode.lowLatency);
        // Keep the source loaded after it finishes — the default
        // ReleaseMode.release would unload it and the next play would be
        // silent (or slow) on some devices.
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setVolume(_volume);
        await p.setSource(AssetSource('sounds/$file.wav'));
        _players[file] = p;
      } catch (e) {
        debugPrint('[Fx] preload $file failed: $e');
      }
    }
  }

  /// Fire the sound and haptic for [fx], respecting the Settings toggles.
  void play(Fx fx) {
    if (hapticsEnabled) unawaited(_haptic(fx));
    if (soundsEnabled) _sound(fx);
  }

  void _sound(Fx fx) {
    final file = _soundFiles[fx];
    if (file == null) return;
    final player = _players[file];
    if (player == null) return;
    final now = DateTime.now();
    if (now.difference(_lastSoundAt) < _throttle) return;
    _lastSoundAt = now;
    unawaited(() async {
      try {
        await player.stop();
        await player.resume();
      } catch (e) {
        debugPrint('[Fx] play $file failed: $e');
      }
    }());
  }

  Future<void> _haptic(Fx fx) async {
    try {
      switch (fx) {
        case Fx.mark:
        case Fx.unmark:
        case Fx.detent:
        case Fx.tap:
          await HapticFeedback.selectionClick();
        case Fx.delete:
        case Fx.groupDone:
          await HapticFeedback.mediumImpact();
        case Fx.keep:
        case Fx.undo:
        case Fx.groupKeep:
          await HapticFeedback.lightImpact();
        case Fx.success:
          await _successPattern();
        case Fx.milestone:
          await _successPattern();
          await Future<void>.delayed(const Duration(milliseconds: 120));
          await HapticFeedback.heavyImpact();
        case Fx.declined:
          await HapticFeedback.mediumImpact();
          await Future<void>.delayed(const Duration(milliseconds: 80));
          await HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }

  Future<void> _successPattern() async {
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }
}
