import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/workout_player/data/drift_completed_session_repository.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  test('enregistre puis relit les séances, les plus récentes d’abord', () async {
    final repository = DriftCompletedSessionRepository(createTestDatabase());
    CompletedSession session(String id, DateTime start) => CompletedSession(
      id: id,
      programId: 'p1',
      programName: 'Haut du corps',
      format: ProgramFormat.strength,
      startedAt: start,
      endedAt: start.add(const Duration(minutes: 20)),
      sets: const [
        CompletedSet(exerciseId: 'push_up', activeSeconds: 40, reps: 12, rpe: 7),
      ],
      activeSeconds: 40,
      xpEarned: 13,
      completed: true,
    );
    final older = session('a', DateTime.utc(2026, 11, 4, 18));
    final newer = session('b', DateTime.utc(2026, 11, 5, 18));

    await repository.save(older);
    await repository.save(newer);

    expect(await repository.readAll(), [newer, older]);
    expect(await repository.watchAll().first, [newer, older]);
  });
}
