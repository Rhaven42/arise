import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/progression/domain/level_curve.dart';
import 'package:arise/features/trials/domain/trial_rules.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// Date et heure locales, par exemple « 13 novembre à 18:05 ».
String formatTrialMoment(DateTime moment) {
  final local = moment.toLocal();
  return '${DateFormat.MMMMd('fr').format(local)} à '
      '${DateFormat.Hm('fr').format(local)}';
}

/// Nom du boss d'une épreuve.
String bossLabel(AppLocalizations l10n, TrialDefinition trial) =>
    l10n.bossName(trial.boss.name);

/// Rang atteint après la victoire sur le boss de [trial].
String nextRankLabel(AppLocalizations l10n, TrialDefinition trial) {
  final last = lastLevelOfRank(trial.rank) ?? 0;
  return l10n.rankName(rankOf(last + 1).name);
}

/// Objet exclusif offert par le boss.
String rewardItemLabel(AppLocalizations l10n, EquipmentItem item) =>
    l10n.itemName(item.id);

/// Objectif de l'épreuve, en une phrase.
String trialGoalLabel(
  AppLocalizations l10n,
  TrialDefinition trial,
  Map<String, Exercise> exercises,
) {
  switch (trial.kind) {
    case TrialKind.strength:
      return l10n.trialGoalStrength(
        trial.repTargets['push_up'] ?? 0,
        trial.repTargets['squat'] ?? 0,
        (trial.timeLimitSeconds ?? 0) ~/ 60,
      );
    case TrialKind.endurance:
      final item = trial.program.items.first;
      return l10n.trialGoalEndurance(
        exercises[item.exerciseId]?.name ?? item.exerciseId,
        (item.durationSeconds ?? 0) ~/ 60,
      );
    case TrialKind.agility:
      return l10n.trialGoalAgility(trial.program.interval?.rounds ?? 0);
  }
}
