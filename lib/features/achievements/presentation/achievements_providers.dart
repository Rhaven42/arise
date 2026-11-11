import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/achievements/data/drift_achievements_repository.dart';
import 'package:arise/features/achievements/domain/achievement_metrics.dart';
import 'package:arise/features/achievements/domain/achievement_rules.dart';
import 'package:arise/features/achievements/domain/achievements_repository.dart';
import 'package:arise/features/achievements/domain/achievements_state.dart';
import 'package:arise/features/exercises/presentation/exercise_providers.dart';
import 'package:arise/features/inventory/presentation/inventory_providers.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/features/quests/presentation/quests_providers.dart';
import 'package:arise/features/shadows/presentation/shadows_providers.dart';
import 'package:arise/features/trials/domain/trials_state.dart';
import 'package:arise/features/trials/presentation/trials_providers.dart';
import 'package:arise/features/workout_player/presentation/workout_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'achievements_providers.g.dart';

@Riverpod(keepAlive: true)
AchievementsRepository achievementsRepository(Ref ref) =>
    DriftAchievementsRepository(
      ref.watch(appDatabaseProvider),
      ref.watch(clockProvider),
    );

/// Hauts faits obtenus.
@Riverpod(keepAlive: true)
Stream<AchievementsState> achievementsState(Ref ref) =>
    ref.watch(achievementsRepositoryProvider).watch();

/// Données des hauts faits, lues directement dans la base (comme les
/// quêtes : les providers écoutés par des pages cachées sont en pause).
Future<AchievementInputs> _inputs(Ref ref, AchievementsState state) async {
  final now = ref.read(clockProvider)();
  final progression =
      await ref.read(progressionRepositoryProvider).read() ??
      ProgressionState.initial(CivilDate.ofLocal(now));
  // Valeurs déjà connues, sinon première lecture.
  final profile =
      ref.read(playerProfileProvider).value ??
      await ref.read(playerProfileProvider.future);
  final database = ref.read(appDatabaseProvider);
  final board = await ref.read(questRepositoryProvider).readBoard();
  return AchievementInputs(
    sessions: await ref.read(completedSessionRepositoryProvider).readAll(),
    exercisesById: await ref.read(exercisesByIdProvider.future),
    progression: progression,
    now: now,
    trials:
        await ref.read(trialsRepositoryProvider).read() ?? const TrialsState(),
    restDays: profile?.restDays ?? const {},
    dailyQuestsDone: state.dailyQuestsDone,
    shadows: (await ref.read(shadowsRepositoryProvider).read()).shadows.length,
    itemsOwned:
        (await ref.read(inventoryRepositoryProvider).read()).owned.length,
    customExercises: (await database.readCustomExerciseJson()).length,
    programs: (await database.readProgramJson()).length,
    eventsCompleted: board.claimedEvents.length,
  );
}

/// Mesures actuelles, pour afficher l'avancement de chaque haut fait.
@riverpod
Future<Map<AchievementMetric, int>> achievementMetrics(Ref ref) async {
  // Recalcul à chaque séance, achat ou haut fait obtenu.
  ref
    ..watch(completedSessionsProvider)
    ..watch(inventoryProvider)
    ..watch(shadowsStateProvider);
  final state = await ref.watch(achievementsStateProvider.future);
  return computeAchievementMetrics(await _inputs(ref, state));
}

/// Évalue et enregistre les hauts faits.
@Riverpod(keepAlive: true)
class AchievementsController extends _$AchievementsController {
  @override
  void build() {}

  /// Évalue les hauts faits (après une séance, ou à l'ouverture de leur
  /// page) et renvoie ceux obtenus maintenant.
  Future<List<AchievementDefinition>> evaluate({
    bool dailyQuestDone = false,
  }) async {
    final repository = ref.read(achievementsRepositoryProvider);
    var state = await repository.read();
    if (dailyQuestDone) state = recordDailyQuest(state);
    final metrics = computeAchievementMetrics(await _inputs(ref, state));
    final update = evaluateAchievements(
      state,
      metrics,
      now: ref.read(clockProvider)(),
    );
    if (dailyQuestDone || update.unlocked.isNotEmpty) {
      await repository.save(update.state);
    }
    return update.unlocked;
  }
}
