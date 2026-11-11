import 'package:arise/core/audio/music.dart';

/// Lecteur de musique de test : mémorise les demandes, ne joue rien.
class FakeMusicPlayer implements MusicPlayer {
  final List<MusicTrack?> tracks = [];
  final List<Jingle> jingles = [];
  bool isEnabled = true;

  @override
  Future<void> play(MusicTrack? track) async => tracks.add(track);

  @override
  Future<void> jingle(Jingle jingle) async => jingles.add(jingle);

  @override
  void setEnabled({required bool enabled}) => isEnabled = enabled;

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}
}
