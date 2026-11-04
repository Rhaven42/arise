import 'package:arise/features/planning/data/drift_planning_repositories.dart';
import 'package:arise/features/planning/domain/planned_session.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  test('enregistre, relit et supprime en cascade un programme', () async {
    final database = createTestDatabase();
    final programs = DriftProgramRepository(database, () => testNow);
    final planning = DriftPlanningRepository(database, () => testNow);
    const program = Program(
      id: 'p1',
      name: 'Haut du corps',
      format: ProgramFormat.strength,
      items: [
        ProgramItem(exerciseId: 'push_up', sets: 3, reps: 12, restSeconds: 60),
      ],
    );
    const session = PlannedSession(
      id: 's1',
      programId: 'p1',
      weekday: DateTime.tuesday,
      minuteOfDay: 1080,
    );

    await programs.save(program);
    await planning.save(session);
    expect(await programs.watchAll().first, [program]);
    expect(await planning.watchAll().first, [session]);

    await programs.delete('p1');
    expect(await programs.watchAll().first, isEmpty);
    expect(await planning.watchAll().first, isEmpty);
  });

  test('met à jour une séance existante sans la dupliquer', () async {
    final database = createTestDatabase();
    final planning = DriftPlanningRepository(database, () => testNow);
    const session = PlannedSession(
      id: 's1',
      programId: 'p1',
      weekday: DateTime.tuesday,
      minuteOfDay: 1080,
    );
    await planning.save(session);
    await planning.save(session.copyWith(weekday: DateTime.friday));

    expect(await planning.watchAll().first, [
      session.copyWith(weekday: DateTime.friday),
    ]);
    await planning.delete('s1');
    expect(await planning.watchAll().first, isEmpty);
  });
}
