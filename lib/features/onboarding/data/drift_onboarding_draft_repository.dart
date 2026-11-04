import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/onboarding/domain/onboarding_draft.dart';
import 'package:arise/features/onboarding/domain/onboarding_draft_repository.dart';

/// Brouillon du questionnaire stocké dans la table des brouillons.
class DriftOnboardingDraftRepository implements OnboardingDraftRepository {
  const DriftOnboardingDraftRepository(this._database);

  static const draftKey = 'onboarding';

  final AppDatabase _database;

  @override
  Future<OnboardingDraft?> load() async {
    final json = await _database.readDraft(draftKey);
    if (json == null) return null;
    try {
      return OnboardingDraft.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } on Object {
      // Brouillon illisible (ancienne version) : on repart de zéro.
      return null;
    }
  }

  @override
  Future<void> save(OnboardingDraft draft) {
    return _database.saveDraft(
      key: draftKey,
      json: jsonEncode(draft.toJson()),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> clear() => _database.deleteDraft(draftKey);
}
