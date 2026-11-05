import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
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
///
/// Les signaux ne doivent jamais interrompre une séance : une erreur de
/// lecture (son ou voix indisponible) est ignorée.
class DeviceWorkoutCues implements WorkoutCues {
  DeviceWorkoutCues();

  /// Un lecteur par son, pour éviter les conflits entre bips rapprochés.
  final _players = <CueSound, AudioPlayer>{};
  FlutterTts? _tts;

  @override
  Future<void> play(CueSound sound) async {
    try {
      await HapticFeedback.mediumImpact();
      var player = _players[sound];
      if (player == null) {
        // La position de lecture n'est pas utilisée : pas de mise à jour à
        // chaque image (économie de batterie).
        player = _players[sound] = AudioPlayer()..positionUpdater = null;
        await player.setReleaseMode(ReleaseMode.stop);
      }
      await player.play(
        AssetSource('sounds/${sound.name}.wav'),
        mode: PlayerMode.lowLatency,
      );
    } on Object catch (error) {
      debugPrint('Signal sonore indisponible : $error');
    }
  }

  @override
  Future<void> speak(String text) async {
    try {
      final tts = _tts ??= FlutterTts();
      await tts.setLanguage('fr-FR');
      await tts.stop();
      await tts.speak(text);
    } on Object catch (error) {
      debugPrint('Synthèse vocale indisponible : $error');
    }
  }

  @override
  Future<void> keepScreenOn({required bool enabled}) async {
    try {
      await (enabled ? WakelockPlus.enable() : WakelockPlus.disable());
    } on Object catch (error) {
      debugPrint('Maintien de l’écran indisponible : $error');
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _tts?.stop();
      for (final player in _players.values) {
        await player.dispose();
      }
    } on Object catch (error) {
      debugPrint('Libération des signaux : $error');
    }
  }
}

@riverpod
WorkoutCues workoutCues(Ref ref) {
  final cues = DeviceWorkoutCues();
  ref.onDispose(() => unawaited(cues.dispose()));
  return cues;
}
