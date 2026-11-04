import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/exercises/data/drift_custom_exercise_repository.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  test('enregistre, modifie et supprime un exercice personnalisé', () async {
    final repository = DriftCustomExerciseRepository(
      createTestDatabase(),
      () => testNow,
    );
    const exercise = Exercise(
      id: 'custom-1',
      name: 'Gainage dynamique',
      type: ExerciseType.duration,
      volumeRule: VolumeRule.cardio,
      stats: {StatId.vitality: 1},
      primaryMuscles: [MuscleId.rectusAbdominis],
      isCustom: true,
    );

    await repository.save(exercise);
    expect(await repository.watchAll().first, [exercise]);

    await repository.save(exercise.copyWith(name: 'Gainage'));
    expect((await repository.watchAll().first).single.name, 'Gainage');

    await repository.delete('custom-1');
    expect(await repository.watchAll().first, isEmpty);
  });
}
