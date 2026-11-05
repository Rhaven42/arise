import 'package:arise/features/progression/data/drift_progression_repository.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  test('enregistre, relit et remplace la progression', () async {
    final repository = DriftProgressionRepository(
      createTestDatabase(),
      () => testNow,
    );
    expect(await repository.read(), isNull);

    final state = ProgressionState.initial(const CivilDate(2026, 11, 4))
        .copyWith(level: 3, crystals: 42);
    await repository.save(state);
    expect(await repository.read(), state);

    await repository.save(state.copyWith(level: 4));
    expect((await repository.watch().first)?.level, 4);
  });
}
