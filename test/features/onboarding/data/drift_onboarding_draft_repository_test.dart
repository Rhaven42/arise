import 'package:arise/features/onboarding/data/drift_onboarding_draft_repository.dart';
import 'package:arise/features/onboarding/domain/onboarding_draft.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  test('enregistre, relit puis efface le brouillon', () async {
    final repository = DriftOnboardingDraftRepository(createTestDatabase());
    const draft = OnboardingDraft(
      step: OnboardingStep.level,
      goal: FitnessGoal.flexibility,
    );

    expect(await repository.load(), isNull);
    await repository.save(draft);
    expect(await repository.load(), draft);
    await repository.clear();
    expect(await repository.load(), isNull);
  });

  test('ignore un brouillon illisible', () async {
    final database = createTestDatabase();
    await database.saveDraft(
      key: DriftOnboardingDraftRepository.draftKey,
      json: '{"step": "inconnue"}',
      updatedAt: testNow,
    );

    expect(await DriftOnboardingDraftRepository(database).load(), isNull);
  });
}
