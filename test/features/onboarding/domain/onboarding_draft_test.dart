import 'package:arise/features/onboarding/domain/onboarding_draft.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const complete = OnboardingDraft(
    step: OnboardingStep.health,
    goal: FitnessGoal.endurance,
    level: FitnessLevel.intermediate,
    restDays: {DateTime.sunday},
    safetyAcknowledged: true,
  );

  group('navigation entre les étapes', () {
    test('commence sur l’objectif et ne recule pas avant', () {
      const draft = OnboardingDraft();
      expect(draft.step, OnboardingStep.goal);
      expect(draft.isFirstStep, isTrue);
      expect(draft.previous().step, OnboardingStep.goal);
    });

    test('avance dans l’ordre et ne dépasse pas la dernière étape', () {
      var draft = const OnboardingDraft();
      for (final step in OnboardingStep.values.skip(1)) {
        draft = draft.next();
        expect(draft.step, step);
      }
      expect(draft.isLastStep, isTrue);
      expect(draft.next().step, OnboardingStep.health);
    });
  });

  group('conditions pour continuer', () {
    test('objectif et niveau sont obligatoires', () {
      expect(const OnboardingDraft().canProceed, isFalse);
      expect(
        const OnboardingDraft(goal: FitnessGoal.strength).canProceed,
        isTrue,
      );
      expect(
        const OnboardingDraft(step: OnboardingStep.level).canProceed,
        isFalse,
      );
    });

    test('aucun équipement est une réponse valide', () {
      expect(
        const OnboardingDraft(step: OnboardingStep.equipment).canProceed,
        isTrue,
      );
    });

    test('il faut de 1 à 3 jours de repos', () {
      const step = OnboardingDraft(step: OnboardingStep.restDays);
      expect(step.canProceed, isFalse);
      expect(step.toggleRestDay(DateTime.monday).canProceed, isTrue);
    });

    test('le rappel de prudence doit être lu', () {
      expect(
        complete.copyWith(safetyAcknowledged: false).canProceed,
        isFalse,
      );
      expect(complete.canProceed, isTrue);
    });
  });

  group('sélections', () {
    test('l’équipement se coche et se décoche', () {
      final once = const OnboardingDraft().toggleEquipment(Equipment.bench);
      expect(once.equipment, {Equipment.bench});
      expect(once.toggleEquipment(Equipment.bench).equipment, isEmpty);
    });

    test('un quatrième jour de repos est ignoré', () {
      var draft = const OnboardingDraft();
      for (final day in [1, 3, 5, 6]) {
        draft = draft.toggleRestDay(day);
      }
      expect(draft.restDays, {1, 3, 5});
      expect(draft.toggleRestDay(3).restDays, {1, 5});
    });

    test('un jour invalide est ignoré', () {
      expect(const OnboardingDraft().toggleRestDay(9).restDays, isEmpty);
    });
  });

  group('création du profil', () {
    test('renvoie null tant qu’une réponse manque', () {
      expect(
        const OnboardingDraft().toProfile(DateTime.utc(2026)),
        isNull,
      );
    });

    test('reprend toutes les réponses', () {
      final now = DateTime.utc(2026, 11, 4);
      final profile = complete
          .toggleEquipment(Equipment.jumpRope)
          .copyWith(healthConsent: true)
          .toProfile(now);

      expect(
        profile,
        PlayerProfile(
          goal: FitnessGoal.endurance,
          level: FitnessLevel.intermediate,
          equipment: const {Equipment.jumpRope},
          restDays: const {DateTime.sunday},
          healthConsent: true,
          createdAt: now,
        ),
      );
    });
  });

  test('le brouillon survit à un aller-retour JSON', () {
    final draft = complete.toggleEquipment(Equipment.kettlebell);
    expect(OnboardingDraft.fromJson(draft.toJson()), draft);
  });
}
