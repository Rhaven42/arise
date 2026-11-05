import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'workout_cues.g.dart';

/// Signal sonore du lecteur.
enum CueSound { countdown, start, rest, finish }

/// Signaux du lecteur de séance : sons, vibrations, voix et écran allumé.
///
/// Tout fonctionne hors ligne (sons embarqués, synthèse vocale du téléphone).
abstract interface class WorkoutCues {
  Future<void> play(CueSound sound);

  Future<void> speak(String text);

  /// Garde l'écran allumé pendant la séance.
  Future<void> keepScreenOn({required bool enabled});

  Future<void> dispose();
}

/// Implémentation sur l'appareil.
class DeviceWorkoutCues implements WorkoutCues {
  DeviceWorkoutCues();

  final _player = AudioPlayer();
  FlutterTts? _tts;

  @override
  Future<void> play(CueSound sound) async {
    await HapticFeedback.mediumImpact();
    await _player.stop();
    await _player.play(AssetSource('sounds/${sound.name}.wav'));
  }

  @override
  Future<void> speak(String text) async {
    final tts = _tts ??= FlutterTts();
    await tts.setLanguage('fr-FR');
    await tts.stop();
    await tts.speak(text);
  }

  @override
  Future<void> keepScreenOn({required bool enabled}) =>
      enabled ? WakelockPlus.enable() : WakelockPlus.disable();

  @override
  Future<void> dispose() async {
    await _tts?.stop();
    await _player.dispose();
  }
}

@riverpod
WorkoutCues workoutCues(Ref ref) {
  final cues = DeviceWorkoutCues();
  ref.onDispose(() => unawaited(cues.dispose()));
  return cues;
}
