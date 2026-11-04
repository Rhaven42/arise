import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'program.freezed.dart';
part 'program.g.dart';

/// Format de séance (SPEC §10.3).
enum ProgramFormat { strength, interval, cardio, mobility }

/// Exercice d'un programme avec ses paramètres.
///
/// Seuls les champs utiles au format du programme sont renseignés :
/// - musculation : séries, répétitions ou durée, charge, repos ;
/// - cardio : durée ou distance ;
/// - mobilité : temps de maintien ;
/// - Tabata/HIIT/circuit : aucun (les temps sont dans [IntervalSettings]).
@freezed
abstract class ProgramItem with _$ProgramItem {
  const factory ProgramItem({
    required String exerciseId,
    int? sets,
    int? reps,
    int? durationSeconds,
    int? distanceMeters,
    double? loadKg,
    int? restSeconds,
    int? holdSeconds,
  }) = _ProgramItem;

  factory ProgramItem.fromJson(Map<String, dynamic> json) =>
      _$ProgramItemFromJson(json);

  /// Paramètres par défaut d'un exercice ajouté à un programme.
  factory ProgramItem.defaultsFor(Exercise exercise, ProgramFormat format) {
    return switch (format) {
      ProgramFormat.strength => ProgramItem(
        exerciseId: exercise.id,
        sets: 3,
        reps: exercise.type == ExerciseType.reps ? 10 : null,
        durationSeconds: exercise.type == ExerciseType.reps ? null : 30,
        restSeconds: 60,
      ),
      ProgramFormat.cardio => ProgramItem(
        exerciseId: exercise.id,
        distanceMeters: exercise.type == ExerciseType.distance ? 2000 : null,
        durationSeconds: exercise.type == ExerciseType.distance ? null : 1200,
      ),
      ProgramFormat.mobility => ProgramItem(
        exerciseId: exercise.id,
        holdSeconds: 30,
      ),
      ProgramFormat.interval => ProgramItem(exerciseId: exercise.id),
    };
  }
}

/// Temps d'un Tabata, d'un HIIT ou d'un circuit.
@freezed
abstract class IntervalSettings with _$IntervalSettings {
  const factory IntervalSettings({
    required int workSeconds,
    required int restSeconds,
    required int rounds,
    required int cycles,
    required int restBetweenCyclesSeconds,
  }) = _IntervalSettings;

  /// Valeurs par défaut : 20 s de travail, 10 s de repos, 8 rounds.
  factory IntervalSettings.defaults() {
    final d = gameConfig.intervalDefaults;
    return IntervalSettings(
      workSeconds: d.workSeconds,
      restSeconds: d.restSeconds,
      rounds: d.rounds,
      cycles: d.cycles,
      restBetweenCyclesSeconds: d.restBetweenCyclesSeconds,
    );
  }

  factory IntervalSettings.fromJson(Map<String, dynamic> json) =>
      _$IntervalSettingsFromJson(json);
}

/// Programme d'entraînement créé par le joueur.
@freezed
abstract class Program with _$Program {
  const factory Program({
    required String id,
    required String name,
    required ProgramFormat format,
    @Default([]) List<ProgramItem> items,
    IntervalSettings? interval,
  }) = _Program;

  factory Program.fromJson(Map<String, dynamic> json) =>
      _$ProgramFromJson(json);
}
