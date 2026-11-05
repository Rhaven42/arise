import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';

const pushUp = Exercise(
  id: 'push_up',
  name: 'Pompes',
  type: ExerciseType.reps,
  volumeRule: VolumeRule.strength,
  stats: {StatId.strength: 1},
  primaryMuscles: [MuscleId.pectoralisMidLower, MuscleId.tricepsBrachii],
  secondaryMuscles: [MuscleId.rectusAbdominis],
);
const row = Exercise(
  id: 'row',
  name: 'Rowing',
  type: ExerciseType.reps,
  volumeRule: VolumeRule.strength,
  stats: {StatId.strength: 1},
  primaryMuscles: [MuscleId.latissimusDorsi],
  secondaryMuscles: [MuscleId.bicepsBrachii],
  equipmentAnyOf: {Equipment.dumbbells},
);
const gluteBridge = Exercise(
  id: 'glute_bridge',
  name: 'Pont fessier',
  type: ExerciseType.reps,
  volumeRule: VolumeRule.strength,
  stats: {StatId.strength: 1},
  primaryMuscles: [MuscleId.gluteusMaximus],
  secondaryMuscles: [MuscleId.hamstrings],
);
const walking = Exercise(
  id: 'walking',
  name: 'Marche',
  type: ExerciseType.duration,
  volumeRule: VolumeRule.cardio,
  stats: {StatId.endurance: 1},
  primaryMuscles: [MuscleId.quadriceps],
);
const stretch = Exercise(
  id: 'stretch',
  name: 'Étirement',
  type: ExerciseType.duration,
  volumeRule: VolumeRule.mobility,
  stats: {StatId.agility: 1},
  primaryMuscles: [MuscleId.hamstrings],
);
const Map<String, Exercise> exercises = {
  'push_up': pushUp,
  'row': row,
  'glute_bridge': gluteBridge,
  'walking': walking,
  'stretch': stretch,
};

CompletedSession session(
  ProgramFormat format,
  List<CompletedSet> sets, {
  DateTime? start,
}) {
  final started = start ?? DateTime(2026, 11, 4, 18);
  return CompletedSession(
    id: started.toIso8601String(),
    programName: 'P',
    format: format,
    startedAt: started.toUtc(),
    endedAt: started.toUtc(),
    sets: sets,
    activeSeconds: 0,
    xpEarned: 0,
    completed: true,
  );
}

CompletedSet set(
  String id, {
  int rpe = 7,
  int seconds = 40,
  bool skip = false,
}) => CompletedSet(
  exerciseId: id,
  activeSeconds: seconds,
  reps: 10,
  rpe: rpe,
  skipped: skip,
);
