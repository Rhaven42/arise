import 'package:freezed_annotation/freezed_annotation.dart';

part 'planned_session.freezed.dart';
part 'planned_session.g.dart';

/// Séance placée dans le planning.
///
/// Une séance récurrente revient chaque semaine le jour [weekday] ; une
/// séance ponctuelle n'a lieu qu'à la date [date] (jour local, sans heure).
@freezed
abstract class PlannedSession with _$PlannedSession {
  const factory PlannedSession({
    required String id,
    required String programId,

    /// Jour de la semaine, comme `DateTime.weekday` (1 = lundi).
    required int weekday,

    /// Heure de début, en minutes depuis minuit (heure locale).
    required int minuteOfDay,
    @Default(true) bool recurring,

    /// Date d'une séance ponctuelle (année, mois, jour).
    DateTime? date,
    @Default(true) bool reminder,
  }) = _PlannedSession;

  factory PlannedSession.fromJson(Map<String, dynamic> json) =>
      _$PlannedSessionFromJson(json);
}
