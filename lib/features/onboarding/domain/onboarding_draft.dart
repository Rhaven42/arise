import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/profile/domain/rest_days_rule.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_draft.freezed.dart';
part 'onboarding_draft.g.dart';

/// Étapes du questionnaire, dans l'ordre.
enum OnboardingStep { goal, level, equipment, restDays, health }

/// Réponses en cours du questionnaire, conservées en brouillon.
@freezed
abstract class OnboardingDraft with _$OnboardingDraft {
  const factory OnboardingDraft({
    @Default(OnboardingStep.goal) OnboardingStep step,
    FitnessGoal? goal,
    FitnessLevel? level,
    @Default(<Equipment>{}) Set<Equipment> equipment,
    @Default(<int>{}) Set<int> restDays,
    @Default(false) bool healthConsent,

    /// L'utilisateur a lu le rappel de prudence (douleur, fatigue extrême).
    @Default(false) bool safetyAcknowledged,
  }) = _OnboardingDraft;

  factory OnboardingDraft.fromJson(Map<String, dynamic> json) =>
      _$OnboardingDraftFromJson(json);
}

/// Règles de progression dans le questionnaire.
extension OnboardingDraftRules on OnboardingDraft {
  bool get isFirstStep => step == OnboardingStep.values.first;

  bool get isLastStep => step == OnboardingStep.values.last;

  /// Vrai si l'étape courante est complète.
  bool get canProceed => switch (step) {
    OnboardingStep.goal => goal != null,
    OnboardingStep.level => level != null,
    // Aucun équipement est une réponse valide (poids du corps).
    OnboardingStep.equipment => true,
    OnboardingStep.restDays => RestDaysRule.isValid(restDays),
    OnboardingStep.health => safetyAcknowledged,
  };

  /// Vrai si toutes les réponses permettent de créer le profil.
  bool get isComplete =>
      goal != null &&
      level != null &&
      RestDaysRule.isValid(restDays) &&
      safetyAcknowledged;

  OnboardingDraft next() => isLastStep
      ? this
      : copyWith(step: OnboardingStep.values[step.index + 1]);

  OnboardingDraft previous() => isFirstStep
      ? this
      : copyWith(step: OnboardingStep.values[step.index - 1]);

  OnboardingDraft toggleEquipment(Equipment item) => copyWith(
    equipment: equipment.contains(item)
        ? ({...equipment}..remove(item))
        : {...equipment, item},
  );

  /// Ajoute ou retire un jour de repos, sans dépasser le maximum autorisé.
  OnboardingDraft toggleRestDay(int weekday) {
    if (!RestDaysRule.isValidWeekday(weekday)) return this;
    if (restDays.contains(weekday)) {
      return copyWith(restDays: {...restDays}..remove(weekday));
    }
    if (!RestDaysRule.canAddMore(restDays)) return this;
    return copyWith(restDays: {...restDays, weekday});
  }

  /// Crée le profil final, ou `null` si une réponse manque.
  PlayerProfile? toProfile(DateTime now) {
    final goal = this.goal;
    final level = this.level;
    if (!isComplete || goal == null || level == null) return null;
    return PlayerProfile(
      goal: goal,
      level: level,
      equipment: equipment,
      restDays: restDays,
      healthConsent: healthConsent,
      createdAt: now.toUtc(),
    );
  }
}
