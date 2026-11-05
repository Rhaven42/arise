import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/coins.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// Date civile au format français, par exemple « 12 novembre 2026 ».
String formatCivilDate(CivilDate date) =>
    DateFormat.yMMMMd('fr').format(DateTime(date.year, date.month, date.day));

/// Montant lisible, par exemple « 2 pièces d'argent, 40 pièces de bronze ».
String formatCoins(AppLocalizations l10n, Coins coins) {
  final parts = [
    if (coins.gold() > 0) l10n.coinGold(coins.gold()),
    if (coins.silver() > 0) l10n.coinSilver(coins.silver()),
    if (coins.bronze() > 0 || coins.isZero) l10n.coinBronze(coins.bronze()),
  ];
  return parts.join(', ');
}
