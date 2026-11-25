import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/world_palette.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/coins.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';

/// Date civile au format français, par exemple « 12 novembre 2026 ».
String formatCivilDate(CivilDate date) =>
    DateFormat.yMMMMd('fr').format(DateTime(date.year, date.month, date.day));

/// Montant lisible, par exemple « 2 pièces d'argent, 40 pièces de bronze ».
String formatCoins(AppLocalizations l10n, Coins coins) {
  // Nom de la monnaie dans l'univers actif.
  final world = WorldPalette.active.id;
  final parts = [
    if (coins.gold() > 0) l10n.coinGold(coins.gold(), world),
    if (coins.silver() > 0) l10n.coinSilver(coins.silver(), world),
    if (coins.bronze() > 0 || coins.isZero)
      l10n.coinBronze(coins.bronze(), world),
  ];
  return parts.join(', ');
}

/// Nom d'une stat dans l'univers actif.
String statLabel(AppLocalizations l10n, StatId stat) =>
    l10n.statNameIn(WorldPalette.active.id, stat.name);

/// Couleur de la gemme de chaque stat.
Color statGemColor(StatId stat) => switch (stat) {
  StatId.strength => AriseColors.gemStrength,
  StatId.endurance => AriseColors.gemEndurance,
  StatId.agility => AriseColors.gemAgility,
  StatId.vitality => AriseColors.gemVitality,
  StatId.willpower => AriseColors.gemWillpower,
};
