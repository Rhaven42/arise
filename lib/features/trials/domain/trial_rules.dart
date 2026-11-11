import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/progression/domain/level_curve.dart';
import 'package:arise/features/progression/domain/progression_rules.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/trials/domain/trials_state.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';

/// Nature d'une épreuve de rang (SPEC §8).
enum TrialKind { strength, endurance, agility }

/// Boss d'Arisia, un par rang (créations originales).
enum BossId {
  rockGuardian,
  silverStag,
  windDancer,
  basaltColossus,
  crimsonComet,
  stormLord,
}

/// Rangs qui ont un boss, dans l'ordre (le Monarque n'en a pas).
const List<RankId> bossRanks = [
  RankId.e,
  RankId.d,
  RankId.c,
  RankId.b,
  RankId.a,
  RankId.s,
];

/// Épreuve qui ouvre le rang suivant.
class TrialDefinition {
  const TrialDefinition({
    required this.rank,
    required this.boss,
    required this.kind,
    required this.requiredStat,
    required this.requiredValue,
    required this.program,
    required this.repTargets,
    required this.rewardItem,
    this.timeLimitSeconds,
  });

  /// Rang dont c'est le boss : le vaincre ouvre le rang suivant.
  final RankId rank;
  final BossId boss;
  final TrialKind kind;
  final StatId requiredStat;
  final int requiredValue;

  /// Séance de l'épreuve, jouée dans le lecteur de séance.
  final Program program;

  /// Répétitions à atteindre par exercice (épreuve de force).
  final Map<String, int> repTargets;

  /// Effort actif maximal, repos exclus (épreuve de force).
  final int? timeLimitSeconds;

  /// Objet exclusif offert à la victoire.
  final EquipmentItem rewardItem;

  /// Titre gagné à la victoire (identifiant stable).
  String get titleId => 'title_${boss.name}';
}

/// Préfixe des identifiants de séance des épreuves.
const String trialProgramPrefix = 'trial_';

/// Rang de l'épreuve désignée par un identifiant de séance, ou `null`.
RankId? trialRankOfProgram(String programId) {
  if (!programId.startsWith(trialProgramPrefix)) return null;
  final name = programId.substring(trialProgramPrefix.length);
  for (final rank in bossRanks) {
    if (rank.name == name) return rank;
  }
  return null;
}

/// Épreuve du boss de [rank], ou `null` pour le Monarque.
///
/// Les natures tournent : force, endurance, agilité. La force se mesure en
/// pompes et squats dans un temps limité, l'endurance en marche (rang E)
/// puis en course chronométrée, l'agilité en circuit (20 s d'effort,
/// 10 s de repos) de jumping jacks et de mountain climbers.
TrialDefinition? trialFor(RankId rank, {GameConfig config = gameConfig}) {
  final index = bossRanks.indexOf(rank);
  if (index < 0) return null;
  final t = config.trials;
  final kind = TrialKind.values[index % TrialKind.values.length];
  final id = '$trialProgramPrefix${rank.name}';
  final boss = BossId.values[index];
  final reward = bossRewardItems[index];
  final requirement = t.statRequirementByRank[index];
  switch (kind) {
    case TrialKind.strength:
      final pushUps = t.strengthPushUpsByRank[index];
      final squats = t.strengthSquatsByRank[index];
      return TrialDefinition(
        rank: rank,
        boss: boss,
        kind: kind,
        requiredStat: StatId.strength,
        requiredValue: requirement,
        repTargets: {'push_up': pushUps, 'squat': squats},
        timeLimitSeconds: t.strengthTimeLimitSeconds,
        rewardItem: reward,
        program: Program(
          id: id,
          name: id,
          format: ProgramFormat.strength,
          items: [
            ProgramItem(
              exerciseId: 'push_up',
              sets: 1,
              reps: pushUps,
              restSeconds: 60,
            ),
            ProgramItem(exerciseId: 'squat', sets: 1, reps: squats),
          ],
        ),
      );
    case TrialKind.endurance:
      return TrialDefinition(
        rank: rank,
        boss: boss,
        kind: kind,
        requiredStat: StatId.endurance,
        requiredValue: requirement,
        repTargets: const {},
        rewardItem: reward,
        program: Program(
          id: id,
          name: id,
          format: ProgramFormat.cardio,
          items: [
            ProgramItem(
              exerciseId: index == 0 ? 'walking' : 'running',
              durationSeconds: t.enduranceMinutesByRank[index] * 60,
            ),
          ],
        ),
      );
    case TrialKind.agility:
      final defaults = config.intervalDefaults;
      return TrialDefinition(
        rank: rank,
        boss: boss,
        kind: kind,
        requiredStat: StatId.agility,
        requiredValue: requirement,
        repTargets: const {},
        rewardItem: reward,
        program: Program(
          id: id,
          name: id,
          format: ProgramFormat.interval,
          items: const [
            ProgramItem(exerciseId: 'jumping_jack'),
            ProgramItem(exerciseId: 'mountain_climber'),
          ],
          interval: IntervalSettings(
            workSeconds: defaults.workSeconds,
            restSeconds: defaults.restSeconds,
            rounds: t.agilityRoundsByRank[index],
            cycles: 1,
            restBetweenCyclesSeconds: defaults.restBetweenCyclesSeconds,
          ),
        ),
      );
  }
}

/// Accès à l'épreuve du rang en cours.
sealed class TrialAccess {
  const TrialAccess();
}

/// L'épreuve peut être tentée.
final class TrialAvailable extends TrialAccess {
  const TrialAvailable(this.trial);

  final TrialDefinition trial;
}

/// Le joueur n'est pas encore au dernier niveau de son rang.
final class TrialNotYet extends TrialAccess {
  const TrialNotYet({required this.trial, required this.unlockLevel});

  final TrialDefinition trial;
  final int unlockLevel;
}

/// La stat de l'épreuve est trop basse.
final class TrialStatTooLow extends TrialAccess {
  const TrialStatTooLow({required this.trial, required this.current});

  final TrialDefinition trial;
  final int current;
}

/// Défaite récente : nouvel essai après le délai.
final class TrialCoolingDown extends TrialAccess {
  const TrialCoolingDown({required this.trial, required this.until});

  final TrialDefinition trial;
  final DateTime until;
}

/// Plus aucun boss (rang Monarque).
final class TrialNone extends TrialAccess {
  const TrialNone();
}

/// Évalue l'accès à l'épreuve du rang actuel du joueur.
TrialAccess trialAccess(
  ProgressionState progression,
  TrialsState trials, {
  required DateTime now,
  GameConfig config = gameConfig,
}) {
  final rank = rankOf(progression.level, config: config);
  final trial = progression.defeatedBosses.contains(rank)
      ? null
      : trialFor(rank, config: config);
  if (trial == null) return const TrialNone();
  final last = lastLevelOfRank(rank, config: config);
  if (last == null || progression.level < last) {
    return TrialNotYet(trial: trial, unlockLevel: last ?? 0);
  }
  final current = progression.stat(trial.requiredStat);
  if (current < trial.requiredValue) {
    return TrialStatTooLow(trial: trial, current: current);
  }
  final defeat = trials.lastDefeatAt[rank];
  if (defeat != null) {
    final until = defeat.add(Duration(hours: config.trials.retryCooldownHours));
    if (now.isBefore(until)) {
      return TrialCoolingDown(trial: trial, until: until);
    }
  }
  return TrialAvailable(trial);
}

/// Vrai si la séance remplit les conditions de l'épreuve : séance complète
/// (sans arrêt pour douleur), répétitions atteintes et temps respecté.
bool isTrialWon(TrialDefinition trial, CompletedSession session) {
  if (!session.completed || session.stoppedForPain) return false;
  final limit = trial.timeLimitSeconds;
  if (limit != null && session.activeSeconds > limit) return false;
  for (final entry in trial.repTargets.entries) {
    final reps = session.sets
        .where((s) => !s.skipped && s.exerciseId == entry.key)
        .fold<int>(0, (sum, s) => sum + (s.reps ?? 0));
    if (reps < entry.value) return false;
  }
  return true;
}

/// Issue d'une épreuve.
class TrialOutcome {
  const TrialOutcome({
    required this.trial,
    required this.won,
    required this.progression,
    required this.trials,
    this.levelsGained = 0,
    this.retryAt,
  });

  final TrialDefinition trial;
  final bool won;
  final ProgressionState progression;
  final TrialsState trials;

  /// Niveaux passés grâce à la victoire (barre pleine débloquée).
  final int levelsGained;

  /// Défaite : date du prochain essai possible.
  final DateTime? retryAt;
}

/// Applique le résultat d'une épreuve jouée.
///
/// - Victoire : boss vaincu, la barre d'XP pleine fait passer le niveau
///   (et donc le rang) immédiatement, le titre est gagné ; l'objet exclusif
///   est livré par l'inventaire.
/// - Défaite : rien n'est perdu, nouvel essai après le délai (48 h).
TrialOutcome resolveTrial({
  required TrialDefinition trial,
  required CompletedSession session,
  required ProgressionState progression,
  required TrialsState trials,
  required DateTime now,
  GameConfig config = gameConfig,
}) {
  final attempts = {
    ...trials.attempts,
    trial.rank: (trials.attempts[trial.rank] ?? 0) + 1,
  };
  if (!isTrialWon(trial, session)) {
    final at = now.toUtc();
    return TrialOutcome(
      trial: trial,
      won: false,
      progression: progression,
      trials: trials.copyWith(
        attempts: attempts,
        lastDefeatAt: {...trials.lastDefeatAt, trial.rank: at},
      ),
      retryAt: at.add(Duration(hours: config.trials.retryCooldownHours)),
    );
  }
  final defeated = progression.copyWith(
    defeatedBosses: {...progression.defeatedBosses, trial.rank},
  );
  final gain = addXp(defeated, 0, config: config);
  return TrialOutcome(
    trial: trial,
    won: true,
    progression: gain.state,
    levelsGained: gain.levelsGained,
    trials: trials.copyWith(
      attempts: attempts,
      lastDefeatAt: {...trials.lastDefeatAt}..remove(trial.rank),
      titles: [
        ...trials.titles,
        if (!trials.titles.contains(trial.titleId)) trial.titleId,
      ],
    ),
  );
}
