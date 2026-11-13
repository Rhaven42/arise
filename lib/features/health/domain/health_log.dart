import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_log.freezed.dart';
part 'health_log.g.dart';

/// Une journée de santé : données lues sur le téléphone (lecture seule),
/// verres d'eau saisis à la main et XP déjà versée ce jour-là.
@freezed
abstract class HealthDay with _$HealthDay {
  const factory HealthDay({
    @CivilDateConverter() required CivilDate day,
    @Default(0) int steps,

    /// Minutes de marche, course ou vélo enregistrées hors de l'application.
    @Default(0) int activityMinutes,

    /// Sommeil de la nuit qui se termine ce jour-là.
    @Default(0) int sleepMinutes,
    @Default(0) int glasses,

    /// XP de stat déjà versée pour cette journée (pour ne jamais compter
    /// deux fois).
    @Default({}) Map<StatId, int> credited,
  }) = _HealthDay;

  factory HealthDay.fromJson(Map<String, dynamic> json) =>
      _$HealthDayFromJson(json);
}

/// Historique santé du joueur (quelques semaines).
@freezed
abstract class HealthLog with _$HealthLog {
  const factory HealthLog({@Default([]) List<HealthDay> days}) = _HealthLog;

  const HealthLog._();

  factory HealthLog.fromJson(Map<String, dynamic> json) =>
      _$HealthLogFromJson(json);

  /// Journée [day], vide si elle n'existe pas encore.
  HealthDay dayOf(CivilDate day) {
    for (final d in days) {
      if (d.day == day) return d;
    }
    return HealthDay(day: day);
  }
}
