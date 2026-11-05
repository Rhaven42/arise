import 'package:arise/core/config/game_config.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Montant en pièces, compté en bronze (100 bronze = 1 argent,
/// 100 argent = 1 or).
@immutable
class Coins {
  const Coins(this.bronzeTotal);

  /// Montant exprimé en pièces de chaque métal.
  factory Coins.of({
    int gold = 0,
    int silver = 0,
    int bronze = 0,
    CoinsConfig? config,
  }) {
    final c = config ?? gameConfig.coins;
    return Coins(gold * c.bronzePerGold + silver * c.bronzePerSilver + bronze);
  }

  static const Coins zero = Coins(0);

  final int bronzeTotal;

  int gold({CoinsConfig? config}) =>
      bronzeTotal ~/ (config ?? gameConfig.coins).bronzePerGold;

  int silver({CoinsConfig? config}) {
    final c = config ?? gameConfig.coins;
    return (bronzeTotal % c.bronzePerGold) ~/ c.bronzePerSilver;
  }

  int bronze({CoinsConfig? config}) =>
      bronzeTotal % (config ?? gameConfig.coins).bronzePerSilver;

  bool get isZero => bronzeTotal == 0;

  Coins operator +(Coins other) => Coins(bronzeTotal + other.bronzeTotal);

  @override
  bool operator ==(Object other) =>
      other is Coins && other.bronzeTotal == bronzeTotal;

  @override
  int get hashCode => bronzeTotal.hashCode;

  @override
  String toString() => 'Coins($bronzeTotal)';
}

/// Pièces gagnées par une séance : l'XP de chaque niveau de difficulté est
/// convertie au taux de ce niveau (les exercices difficiles rapportent plus).
///
/// [xpByDifficulty] : XP de base par difficulté (1 à 3), [multiplier] : bonus
/// de série et malus de pénalité, appliqués comme pour l'XP.
Coins sessionCoins(
  Map<int, int> xpByDifficulty, {
  double multiplier = 1,
  CoinsConfig? config,
}) {
  final c = config ?? gameConfig.coins;
  final rates = c.bronzePerXpByDifficulty;
  var total = 0.0;
  for (final entry in xpByDifficulty.entries) {
    final index = (entry.key - 1).clamp(0, rates.length - 1);
    total += entry.value * multiplier * rates[index];
  }
  return Coins(total.round());
}
