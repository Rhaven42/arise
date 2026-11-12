import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/coins.dart';
import 'package:arise/features/progression/domain/hero_class.dart';
import 'package:arise/features/progression/domain/level_curve.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'progression_state.freezed.dart';
part 'progression_state.g.dart';

/// Progression du joueur : niveau, stats, pièces, série de jours.
///
/// Toutes les règles qui la modifient sont dans `progression_rules.dart`.
@freezed
abstract class ProgressionState with _$ProgressionState {
  const factory ProgressionState({
    /// Dernier jour déjà évalué par la bascule quotidienne.
    @CivilDateConverter() required CivilDate lastRolloverDay,
    @Default(0) int level,

    /// XP accumulée vers le niveau suivant.
    @Default(0) int xpInLevel,
    @Default(0) int totalXp,

    /// Points placés par le joueur dans chaque stat.
    @Default({}) Map<StatId, int> allocatedStats,

    /// XP gagnée par stat grâce aux exercices (points automatiques).
    @Default({}) Map<StatId, int> statXp,

    /// Volonté gagnée par la régularité.
    @Default(0) int willpowerEarned,
    @Default(0) int freeStatPoints,

    /// Portefeuille, compté en bronze (voir [Coins]). Les anciennes
    /// sauvegardes stockaient des cristaux : ils deviennent du bronze.
    @JsonKey(readValue: _readCoins) @Default(0) int coins,

    /// Série de jours validés en cours et record.
    @Default(0) int streakDays,
    @Default(0) int bestStreak,
    @NullableCivilDateConverter() CivilDate? lastValidatedDay,
    @Default(0) int shields,

    /// Jours écoulés depuis le dernier bouclier gagné.
    @Default(0) int shieldProgressDays,

    /// Fin du malus de la Zone de Pénalité.
    DateTime? penaltyUntil,

    /// Dernier jour du mode maladie ou blessure (inclus).
    @NullableCivilDateConverter() CivilDate? sickUntil,

    @Default({}) Set<RankId> defeatedBosses,

    /// Classe choisie à partir du rang C (phase 8B) et date du dernier
    /// choix (un changement par mois).
    HeroClass? heroClass,
    DateTime? classChangedAt,
  }) = _ProgressionState;

  const ProgressionState._();

  /// Progression d'un nouveau joueur : le jour de création n'est jamais
  /// compté comme manqué.
  factory ProgressionState.initial(CivilDate today) =>
      ProgressionState(lastRolloverDay: today);

  factory ProgressionState.fromJson(Map<String, dynamic> json) =>
      _$ProgressionStateFromJson(json);

  RankId get rank => rankOf(level);

  Coins get wallet => Coins(coins);

  /// XP nécessaire pour atteindre le niveau suivant.
  int get xpForNextLevel => xpToNextLevel(level);

  bool get isAtMaxLevel => level >= gameConfig.progression.maxLevel;

  /// Vrai si l'XP est bloquée en attendant le boss du rang.
  bool get isRankLocked => rankLockedAt(level, defeatedBosses);

  /// Valeur d'une stat : points placés + points gagnés par l'entraînement
  /// (ou par la régularité pour la Volonté).
  int stat(StatId id) {
    final allocated = allocatedStats[id] ?? 0;
    if (id == StatId.willpower) return allocated + willpowerEarned;
    return allocated +
        (statXp[id] ?? 0) ~/ gameConfig.progression.statXpPerPoint;
  }

  /// Points placés à la main dans une stat.
  int allocatedIn(StatId id) => allocatedStats[id] ?? 0;

  /// XP d'entraînement accumulée vers le prochain point automatique de la
  /// stat, ou `null` pour la Volonté (gagnée par la régularité seule).
  int? statXpTowardNextPoint(StatId id) {
    if (id == StatId.willpower) return null;
    return (statXp[id] ?? 0) % gameConfig.progression.statXpPerPoint;
  }

  bool isPenaltyActive(DateTime now) {
    final until = penaltyUntil;
    return until != null && now.isBefore(until);
  }

  bool isSickOn(CivilDate day) {
    final until = sickUntil;
    return until != null && !day.isAfter(until);
  }
}

/// Lit le portefeuille, ou les cristaux des sauvegardes d'avant la phase 6.
Object? _readCoins(Map<dynamic, dynamic> json, String key) =>
    json[key] ?? json['crystals'];
