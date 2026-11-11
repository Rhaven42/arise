import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/features/trials/data/drift_trials_repository.dart';
import 'package:arise/features/trials/domain/trial_rules.dart';
import 'package:arise/features/trials/domain/trials_repository.dart';
import 'package:arise/features/trials/domain/trials_state.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trials_providers.g.dart';

@Riverpod(keepAlive: true)
TrialsRepository trialsRepository(Ref ref) => DriftTrialsRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(clockProvider),
);

/// Historique des épreuves (vide avant le premier essai).
@Riverpod(keepAlive: true)
Stream<TrialsState> trialsState(Ref ref) => ref
    .watch(trialsRepositoryProvider)
    .watch()
    .map((state) => state ?? const TrialsState());

/// Accès à l'épreuve du rang actuel.
@riverpod
Future<TrialAccess> trialAccessNow(Ref ref) async {
  final progression = (await ref.watch(progressionControllerProvider.future))
      .state;
  final trials = await ref.watch(trialsStateProvider.future);
  return trialAccess(progression, trials, now: ref.read(clockProvider)());
}

/// Règle les épreuves jouées dans le lecteur de séance.
@Riverpod(keepAlive: true)
class TrialController extends _$TrialController {
  @override
  void build() {}

  /// Applique le résultat de la séance d'une épreuve : victoire (boss
  /// vaincu, rang, titre, objet exclusif) ou défaite (délai de 48 h).
  /// Renvoie `null` si la séance n'est pas une épreuve accessible.
  Future<TrialOutcome?> resolve(CompletedSession session) async {
    final programId = session.programId;
    if (programId == null) return null;
    final rank = trialRankOfProgram(programId);
    if (rank == null) return null;
    final repository = ref.read(trialsRepositoryProvider);
    final progression = (await ref.read(progressionControllerProvider.future))
        .state;
    final trials = await repository.read() ?? const TrialsState();
    final now = ref.read(clockProvider)();
    // L'épreuve doit être celle du rang en cours et accessible au départ.
    final access = trialAccess(progression, trials, now: now);
    if (access is! TrialAvailable || access.trial.rank != rank) return null;
    final outcome = resolveTrial(
      trial: access.trial,
      session: session,
      progression: progression,
      trials: trials,
      now: now,
    );
    final inventory = outcome.won ? await repository.readInventory() : null;
    final rewardId = outcome.trial.rewardItem.id;
    await repository.saveOutcome(
      trials: outcome.trials,
      progression: outcome.progression,
      inventory: inventory == null || inventory.owned.contains(rewardId)
          ? null
          : inventory.copyWith(owned: [...inventory.owned, rewardId]),
    );
    await ref
        .read(progressionControllerProvider.notifier)
        .adopt(outcome.progression);
    ref.invalidate(trialAccessNowProvider);
    return outcome;
  }
}

/// Séance d'une épreuve, nommée d'après son boss, ou `null`.
Program? trialProgramFor(String programId) {
  final rank = trialRankOfProgram(programId);
  if (rank == null) return null;
  final trial = trialFor(rank);
  if (trial == null) return null;
  final l10n = lookupAppLocalizations(const Locale('fr'));
  return trial.program.copyWith(name: l10n.bossName(trial.boss.name));
}
