import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/exercises/presentation/exercise_providers.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/features/quests/data/drift_quest_repository.dart';
import 'package:arise/features/quests/domain/daily_quest.dart';
import 'package:arise/features/quests/domain/quest_repository.dart';
import 'package:arise/features/quests/domain/quest_rules.dart';
import 'package:arise/features/workout_player/presentation/workout_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quests_providers.g.dart';

/// Identifiant de la séance qui termine la quête quotidienne.
const String dailyQuestProgramId = 'quest_daily';

/// Identifiant de la séance de la quête de pénalité.
const String penaltyQuestProgramId = 'quest_penalty';

@Riverpod(keepAlive: true)
QuestRepository questRepository(Ref ref) => DriftQuestRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(clockProvider),
);

/// Quête du jour et sa progression, prêtes à afficher.
class QuestView {
  const QuestView({
    required this.quest,
    required this.progress,
    required this.penaltyActive,
    required this.penaltyObjectives,
    required this.penaltyProgress,
  });

  final DailyQuest quest;
  final List<int> progress;

  /// Malus de la Zone de Pénalité actif : la quête de pénalité est proposée.
  final bool penaltyActive;
  final List<QuestObjective> penaltyObjectives;
  final List<int> penaltyProgress;

  bool get completed => objectivesMet(quest.objectives, progress);
}

/// Quête quotidienne : générée au premier affichage du jour, recalculée à
/// chaque séance enregistrée.
@Riverpod(keepAlive: true)
class QuestController extends _$QuestController {
  @override
  Future<QuestView?> build() async {
    final profile = await ref.watch(playerProfileProvider.future);
    if (profile == null) return null;
    final sessions = await ref.watch(completedSessionsProvider.future);
    final progression = (await ref.watch(progressionControllerProvider.future))
        .state;
    final now = ref.read(clockProvider)();
    final today = CivilDate.ofLocal(now);
    final repository = ref.read(questRepositoryProvider);
    var quest = await repository.read();
    if (quest == null || quest.day != today) {
      final catalog = await ref.read(exerciseCatalogProvider.future);
      quest = generateDailyQuest(
        day: today,
        profile: profile,
        playerLevel: progression.level,
        sick: progression.isSickOn(today),
        catalog: catalog,
      );
      await repository.save(quest);
    }
    final penalty = penaltyObjectives(quest);
    return QuestView(
      quest: quest,
      progress: questProgress(quest.objectives, today, sessions),
      penaltyActive: progression.isPenaltyActive(now) && !quest.penaltyCleared,
      penaltyObjectives: penalty,
      penaltyProgress: questProgress(penalty, today, sessions),
    );
  }

  /// Évalue les quêtes après une séance : quête de pénalité, récompense de
  /// la quête quotidienne. Renvoie le bilan à annoncer.
  Future<QuestOutcome?> evaluate() async {
    final view = await future;
    if (view == null) return null;
    final profile = await ref.read(playerProfileProvider.future);
    final progression = (await ref.read(progressionControllerProvider.future))
        .state;
    final sessions = await ref
        .read(completedSessionRepositoryProvider)
        .readAll();
    final outcome = evaluateQuests(
      quest: view.quest,
      state: progression,
      sessions: sessions,
      now: ref.read(clockProvider)(),
      restDays: profile?.restDays ?? const {},
    );
    if (outcome.quest != view.quest || outcome.state != progression) {
      await ref
          .read(questRepositoryProvider)
          .saveWithProgression(outcome.quest, outcome.state);
      await ref
          .read(progressionControllerProvider.notifier)
          .adopt(outcome.state);
    }
    ref.invalidateSelf();
    return outcome;
  }
}

/// Séance générée pour une quête (objectifs restants), ou `null`.
Future<Program?> questProgramFor(Ref ref, String programId) async {
  if (programId != dailyQuestProgramId && programId != penaltyQuestProgramId) {
    return null;
  }
  final view = await ref.read(questControllerProvider.future);
  if (view == null) return null;
  final l10n = lookupAppLocalizations(const Locale('fr'));
  final penalty = programId == penaltyQuestProgramId;
  return questProgram(
    id: programId,
    name: penalty ? l10n.questPenaltyTitle : l10n.questDailyTitle,
    objectives: penalty ? view.penaltyObjectives : view.quest.objectives,
    progress: penalty ? view.penaltyProgress : view.progress,
  );
}
