import 'package:arise/features/onboarding/domain/onboarding_draft.dart';
import 'package:arise/features/onboarding/presentation/onboarding_controller.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  test('chaque réponse est conservée en brouillon', () async {
    final database = createTestDatabase();
    final container = createTestContainer(database: database)
      ..listen(onboardingControllerProvider, (_, _) {});
    final controller = container.read(onboardingControllerProvider.notifier);
    await container.read(onboardingControllerProvider.future);

    await controller.selectGoal(FitnessGoal.weightLoss);
    await controller.next();

    final saved = await container
        .read(onboardingDraftRepositoryProvider)
        .load();
    expect(saved?.goal, FitnessGoal.weightLoss);
    expect(saved?.step, OnboardingStep.level);
  });

  test('reprend le brouillon au lancement suivant', () async {
    final database = createTestDatabase();
    final first = createTestContainer(database: database)
      ..listen(onboardingControllerProvider, (_, _) {});
    await first.read(onboardingControllerProvider.future);
    await first
        .read(onboardingControllerProvider.notifier)
        .selectLevel(FitnessLevel.advanced);

    final second = createTestContainer(database: database)
      ..listen(onboardingControllerProvider, (_, _) {});
    final restored = await second.read(onboardingControllerProvider.future);
    expect(restored.level, FitnessLevel.advanced);
  });

  test('refuse de valider un questionnaire incomplet', () async {
    final container = createTestContainer()
      ..listen(onboardingControllerProvider, (_, _) {});
    await container.read(onboardingControllerProvider.future);

    final saved = await container
        .read(onboardingControllerProvider.notifier)
        .submit();

    expect(saved, isFalse);
  });

  test('crée le profil et efface le brouillon à la validation', () async {
    final container = createTestContainer()
      ..listen(onboardingControllerProvider, (_, _) {});
    final controller = container.read(onboardingControllerProvider.notifier);
    await container.read(onboardingControllerProvider.future);

    await controller.selectGoal(FitnessGoal.strength);
    await controller.selectLevel(FitnessLevel.beginner);
    await controller.toggleEquipment(Equipment.dumbbells);
    await controller.toggleRestDay(DateTime.wednesday);
    await controller.toggleRestDay(DateTime.sunday);
    await controller.setSafetyAcknowledged(value: true);

    expect(await controller.submit(), isTrue);

    final profile = await container
        .read(profileRepositoryProvider)
        .watchProfile()
        .first;
    expect(profile, sampleProfile);
    expect(
      await container.read(onboardingDraftRepositoryProvider).load(),
      isNull,
    );
  });
}
