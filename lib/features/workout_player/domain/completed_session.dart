import 'package:arise/features/planning/domain/program.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'completed_session.freezed.dart';
part 'completed_session.g.dart';

/// Origine d'une séance enregistrée.
enum SessionSource { manual, health }

/// Effort réalisé pendant une séance.
@freezed
abstract class CompletedSet with _$CompletedSet {
  const factory CompletedSet({
    required String exerciseId,
    required int activeSeconds,
    int? reps,
    int? meters,
    double? loadKg,
    int? rpe,
    @Default(false) bool skipped,
  }) = _CompletedSet;

  factory CompletedSet.fromJson(Map<String, dynamic> json) =>
      _$CompletedSetFromJson(json);
}

/// Séance terminée (ou interrompue), enregistrée sur le téléphone.
@freezed
abstract class CompletedSession with _$CompletedSession {
  const factory CompletedSession({
    required String id,
    required String programName,
    required ProgramFormat format,
    required DateTime startedAt,
    required DateTime endedAt,
    required List<CompletedSet> sets,

    /// Effort actif total (repos et pauses exclus).
    required int activeSeconds,
    required int xpEarned,

    /// Vrai si tous les efforts prévus ont été réalisés.
    required bool completed,

    /// Nombre d'efforts prévus par le programme (0 dans les anciennes
    /// sauvegardes, où il n'était pas enregistré).
    @Default(0) int plannedEfforts,
    String? programId,
    @Default(false) bool stoppedForPain,

    /// Vrai si le plafond quotidien d'effort a été dépassé pendant la séance.
    @Default(false) bool exceededDailyCap,
    @Default(SessionSource.manual) SessionSource source,
  }) = _CompletedSession;

  factory CompletedSession.fromJson(Map<String, dynamic> json) =>
      _$CompletedSessionFromJson(json);
}
