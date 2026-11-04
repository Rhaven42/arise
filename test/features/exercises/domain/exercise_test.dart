import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/exercise_filter.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise _exercise(
  String id,
  String name, {
  Set<Equipment> equipment = const {},
  Map<StatId, double> stats = const {StatId.strength: 1},
  List<MuscleId> primary = const [MuscleId.quadriceps],
  List<MuscleId> secondary = const [],
  ReviewStatus status = ReviewStatus.validated,
}) => Exercise(
  id: id,
  name: name,
  type: ExerciseType.reps,
  volumeRule: VolumeRule.strength,
  stats: stats,
  primaryMuscles: primary,
  secondaryMuscles: secondary,
  equipmentAnyOf: equipment,
  reviewStatus: status,
);

void main() {
  group('Exercise', () {
    test('la stat principale est celle qui a la plus grande part', () {
      final e = _exercise(
        'b',
        'Burpees',
        stats: const {StatId.strength: 0.3, StatId.endurance: 0.7},
      );
      expect(e.mainStat, StatId.endurance);
    });

    test('l’équipement : un seul élément suffit, aucun = poids du corps', () {
      final row = _exercise(
        'r',
        'Rowing',
        equipment: const {Equipment.dumbbells, Equipment.barbell},
      );
      expect(row.isAvailableWith(const {Equipment.barbell}), isTrue);
      expect(row.isAvailableWith(const {Equipment.bench}), isFalse);
      expect(_exercise('s', 'Squat').isAvailableWith(const {}), isTrue);
    });

    test('rôles des muscles et sérialisation JSON', () {
      final e = _exercise(
        'p',
        'Pompes',
        primary: const [MuscleId.tricepsBrachii],
        secondary: const [MuscleId.serratusAnterior],
      );
      expect(e.muscleRoles, {
        MuscleId.tricepsBrachii: MuscleRole.primary,
        MuscleId.serratusAnterior: MuscleRole.secondary,
      });
      expect(Exercise.fromJson(e.toJson()), e);
      expect(e.toJson()['primaryMuscles'], ['triceps_brachii']);
    });

    test('un exercice à relire n’est pas publiable', () {
      expect(
        _exercise('x', 'X', status: ReviewStatus.pendingReview).isPublishable,
        isFalse,
      );
    });
  });

  group('filterExercises', () {
    final exercises = [
      _exercise('squat', 'Squat'),
      _exercise(
        'row',
        'Rowing',
        equipment: const {Equipment.dumbbells},
        primary: const [MuscleId.latissimusDorsi],
      ),
      _exercise('run', 'Élan', stats: const {StatId.endurance: 1}),
      _exercise('hidden', 'Caché', status: ReviewStatus.pendingReview),
    ];

    List<String> ids(
      ExerciseFilter filter, {
      Set<Equipment> owned = const {},
    }) => [
      for (final e in filterExercises(exercises, filter, ownedEquipment: owned))
        e.id,
    ];

    test('trie par nom et masque les exercices à relire', () {
      expect(ids(const ExerciseFilter()), ['run', 'row', 'squat']);
    });

    test('recherche sans tenir compte des accents ni de la casse', () {
      expect(ids(const ExerciseFilter(query: 'ELAN')), ['run']);
    });

    test('filtre par muscle, stat et équipement possédé', () {
      expect(ids(const ExerciseFilter(muscle: MuscleId.latissimusDorsi)), [
        'row',
      ]);
      expect(ids(const ExerciseFilter(stat: StatId.endurance)), ['run']);
      expect(ids(const ExerciseFilter(onlyAvailable: true)), ['run', 'squat']);
      expect(
        ids(
          const ExerciseFilter(onlyAvailable: true),
          owned: const {Equipment.dumbbells},
        ),
        ['run', 'row', 'squat'],
      );
    });
  });
}
