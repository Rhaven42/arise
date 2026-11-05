import 'package:arise/features/workout_player/presentation/workout_cues.dart';

/// Faux signaux du lecteur : mémorise les sons et les phrases demandés.
class FakeWorkoutCues implements WorkoutCues {
  final sounds = <CueSound>[];
  final spoken = <String>[];
  bool screenOn = false;

  @override
  Future<void> play(CueSound sound) async => sounds.add(sound);

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> keepScreenOn({required bool enabled}) async =>
      screenOn = enabled;

  @override
  Future<void> dispose() async {}
}
