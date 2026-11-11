import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'music.g.dart';

/// Musiques d'ambiance (créations de la propriétaire du projet, docs/ASSETS.md).
enum MusicTrack {
  /// Écran titre et questionnaire.
  title,

  /// Fenêtre du Système et écrans de jeu.
  system,

  /// Boutique et inventaire.
  shop,
}

/// Courts jingles joués par-dessus la musique.
enum Jingle { levelUp }

/// Musique de l'application : une piste en boucle, avec fondus, et des
/// jingles. Une erreur de lecture n'interrompt jamais l'application.
abstract interface class MusicPlayer {
  /// Joue [track] en boucle (fondu depuis la piste en cours), ou coupe la
  /// musique si [track] est `null`.
  Future<void> play(MusicTrack? track);

  Future<void> jingle(Jingle jingle);

  /// Musique et jingles activés (réglage du joueur).
  void setEnabled({required bool enabled});

  /// Application en arrière-plan : la musique se met en pause.
  Future<void> pause();

  Future<void> resume();
}

/// Lecteur sur l'appareil (audioplayers), qui se mélange aux autres sons du
/// téléphone et respecte le mode silencieux.
class DeviceMusicPlayer implements MusicPlayer {
  DeviceMusicPlayer();

  static const _volume = 0.55;
  static const _fade = Duration(milliseconds: 900);

  AudioPlayer? _music;
  AudioPlayer? _jingle;
  MusicTrack? _track;
  bool _enabled = true;
  int _generation = 0;

  AudioContext get _context => AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
    respectSilence: true,
  ).build();

  Future<AudioPlayer> _musicPlayer() async {
    final existing = _music;
    if (existing != null) return existing;
    final player = AudioPlayer()..positionUpdater = null;
    await player.setAudioContext(_context);
    await player.setReleaseMode(ReleaseMode.loop);
    return _music = player;
  }

  Future<void> _fadeTo(
    AudioPlayer player,
    double target,
    int generation,
  ) async {
    const steps = 9;
    final start = player.volume;
    for (var i = 1; i <= steps; i++) {
      if (generation != _generation) return;
      await player.setVolume(start + (target - start) * i / steps);
      await Future<void>.delayed(_fade ~/ steps);
    }
  }

  @override
  Future<void> play(MusicTrack? track) async {
    if (track == _track) return;
    _track = track;
    final generation = ++_generation;
    try {
      final player = await _musicPlayer();
      if (player.state == PlayerState.playing) {
        await _fadeTo(player, 0, generation);
        if (generation != _generation) return;
        await player.stop();
      }
      if (track == null || !_enabled) return;
      await player.setVolume(0);
      await player.play(AssetSource('music/${track.name}.mp3'));
      await _fadeTo(player, _volume, generation);
    } on Object catch (error) {
      debugPrint('Musique indisponible : $error');
    }
  }

  @override
  Future<void> jingle(Jingle jingle) async {
    if (!_enabled) return;
    try {
      var player = _jingle;
      if (player == null) {
        player = _jingle = AudioPlayer()..positionUpdater = null;
        await player.setAudioContext(_context);
        await player.setReleaseMode(ReleaseMode.stop);
      }
      // La musique s'efface sous le jingle puis revient.
      final music = _music;
      final generation = _generation;
      if (music != null && music.state == PlayerState.playing) {
        unawaited(_fadeTo(music, _volume * 0.25, generation));
      }
      await player.play(AssetSource('sounds/level_up.mp3'));
      unawaited(
        player.onPlayerComplete.first.then((_) async {
          final current = _music;
          if (current != null && generation == _generation) {
            await _fadeTo(current, _volume, generation);
          }
        }),
      );
    } on Object catch (error) {
      debugPrint('Jingle indisponible : $error');
    }
  }

  @override
  void setEnabled({required bool enabled}) {
    if (enabled == _enabled) return;
    _enabled = enabled;
    final track = _track;
    _track = null;
    unawaited(play(enabled ? track : null));
    if (!enabled) _track = track;
  }

  @override
  Future<void> pause() async {
    try {
      await _music?.pause();
    } on Object catch (error) {
      debugPrint('Musique indisponible : $error');
    }
  }

  @override
  Future<void> resume() async {
    if (!_enabled || _track == null) return;
    try {
      await _music?.resume();
    } on Object catch (error) {
      debugPrint('Musique indisponible : $error');
    }
  }
}

/// Lecteur de musique de l'application (remplacé par un faux dans les tests).
@Riverpod(keepAlive: true)
MusicPlayer musicPlayer(Ref ref) => DeviceMusicPlayer();

/// Piste à jouer pour un écran (chemin du routeur), ou `null` pour le
/// silence (lecteur de séance : il a ses propres signaux).
MusicTrack? musicForLocation(String location) {
  if (location.contains('/workout/')) return null;
  if (location.startsWith('/system/shop') ||
      location.startsWith('/system/inventory')) {
    return MusicTrack.shop;
  }
  if (location.startsWith('/system')) return MusicTrack.system;
  return MusicTrack.title;
}
