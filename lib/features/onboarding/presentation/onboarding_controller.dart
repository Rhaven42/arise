import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/onboarding/data/drift_onboarding_draft_repository.dart';
import 'package:arise/features/onboarding/domain/onboarding_draft.dart';
import 'package:arise/features/onboarding/domain/onboarding_draft_repository.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.g.dart';

@Riverpod(keepAlive: true)
OnboardingDraftRepository onboardingDraftRepository(Ref ref) {
  return DriftOnboardingDraftRepository(ref.watch(appDatabaseProvider));
}

/// Pilote le questionnaire : chaque réponse est enregistrée en brouillon.
@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  Future<OnboardingDraft> build() async {
    final saved = await ref.watch(onboardingDraftRepositoryProvider).load();
    return saved ?? const OnboardingDraft();
  }

  Future<void> _update(OnboardingDraft Function(OnboardingDraft) change) async {
    final current = state.value;
    if (current == null) return;
    final updated = change(current);
    state = AsyncData(updated);
    await ref.read(onboardingDraftRepositoryProvider).save(updated);
  }

  Future<void> selectGoal(FitnessGoal goal) =>
      _update((draft) => draft.copyWith(goal: goal));

  Future<void> selectLevel(FitnessLevel level) =>
      _update((draft) => draft.copyWith(level: level));

  Future<void> toggleEquipment(Equipment item) =>
      _update((draft) => draft.toggleEquipment(item));

  Future<void> toggleRestDay(int weekday) =>
      _update((draft) => draft.toggleRestDay(weekday));

  Future<void> setHealthConsent({required bool value}) =>
      _update((draft) => draft.copyWith(healthConsent: value));

  Future<void> setSafetyAcknowledged({required bool value}) =>
      _update((draft) => draft.copyWith(safetyAcknowledged: value));

  Future<void> next() => _update((draft) => draft.next());

  Future<void> previous() => _update((draft) => draft.previous());

  /// Enregistre le profil et efface le brouillon.
  ///
  /// Renvoie `false` si une réponse manque.
  Future<bool> submit() async {
    final draft = state.value;
    final profile = draft?.toProfile(ref.read(clockProvider)());
    if (profile == null) return false;
    await ref.read(profileRepositoryProvider).saveProfile(profile);
    await ref.read(onboardingDraftRepositoryProvider).clear();
    return true;
  }
}
