import 'package:arise/features/onboarding/domain/onboarding_draft.dart';

/// Conservation du brouillon du questionnaire entre deux lancements.
abstract interface class OnboardingDraftRepository {
  Future<OnboardingDraft?> load();

  Future<void> save(OnboardingDraft draft);

  Future<void> clear();
}
