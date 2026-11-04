import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/planning/domain/program.dart';

/// Problème empêchant d'enregistrer un programme.
enum ProgramIssue {
  nameTooShort,
  nameTooLong,
  noExercise,
  invalidSets,
  invalidReps,
  invalidDuration,
  invalidDistance,
  invalidLoad,
  invalidRest,
  invalidHold,
  invalidInterval,
}

/// Bornes de saisie (garde-fous, pas des valeurs d'équilibrage).
abstract final class ProgramLimits {
  static const nameMin = 3;
  static const nameMax = 40;
  static const sets = (min: 1, max: 20);
  static const reps = (min: 1, max: 500);
  static const durationSeconds = (min: 5, max: 4 * 3600);
  static const distanceMeters = (min: 10, max: 200000);
  static const restSeconds = (min: 0, max: 900);
  static const holdSeconds = (min: 5, max: 600);
  static const loadKg = (min: 0.0, max: 500.0);
  static const workSeconds = (min: 5, max: 600);
  static const intervalRestSeconds = (min: 0, max: 600);
  static const rounds = (min: 1, max: 50);
  static const cycles = (min: 1, max: 10);
  static const restBetweenCyclesSeconds = (min: 0, max: 900);
}

bool _within(num? value, ({num min, num max}) range) =>
    value != null && value >= range.min && value <= range.max;

/// Vérifie un programme avant enregistrement.
Set<ProgramIssue> validateProgram(Program program) {
  final issues = <ProgramIssue>{};
  final name = program.name.trim();
  if (name.length < ProgramLimits.nameMin)
    issues.add(ProgramIssue.nameTooShort);
  if (name.length > ProgramLimits.nameMax) issues.add(ProgramIssue.nameTooLong);
  if (program.items.isEmpty) issues.add(ProgramIssue.noExercise);

  for (final item in program.items) {
    switch (program.format) {
      case ProgramFormat.strength:
        if (!_within(item.sets, ProgramLimits.sets)) {
          issues.add(ProgramIssue.invalidSets);
        }
        final hasReps = item.reps != null;
        final hasDuration = item.durationSeconds != null;
        if (hasReps == hasDuration) {
          issues.add(ProgramIssue.invalidReps);
        } else if (hasReps && !_within(item.reps, ProgramLimits.reps)) {
          issues.add(ProgramIssue.invalidReps);
        } else if (hasDuration &&
            !_within(item.durationSeconds, ProgramLimits.durationSeconds)) {
          issues.add(ProgramIssue.invalidDuration);
        }
        if (!_within(item.restSeconds, ProgramLimits.restSeconds)) {
          issues.add(ProgramIssue.invalidRest);
        }
        final load = item.loadKg;
        if (load != null && !_within(load, ProgramLimits.loadKg)) {
          issues.add(ProgramIssue.invalidLoad);
        }
      case ProgramFormat.cardio:
        final hasDistance = item.distanceMeters != null;
        final hasDuration = item.durationSeconds != null;
        if (hasDistance == hasDuration) {
          issues.add(ProgramIssue.invalidDuration);
        } else if (hasDistance &&
            !_within(item.distanceMeters, ProgramLimits.distanceMeters)) {
          issues.add(ProgramIssue.invalidDistance);
        } else if (hasDuration &&
            !_within(item.durationSeconds, ProgramLimits.durationSeconds)) {
          issues.add(ProgramIssue.invalidDuration);
        }
      case ProgramFormat.mobility:
        if (!_within(item.holdSeconds, ProgramLimits.holdSeconds)) {
          issues.add(ProgramIssue.invalidHold);
        }
      case ProgramFormat.interval:
        break;
    }
  }

  if (program.format == ProgramFormat.interval) {
    final settings = program.interval;
    if (settings == null ||
        !_within(settings.workSeconds, ProgramLimits.workSeconds) ||
        !_within(settings.restSeconds, ProgramLimits.intervalRestSeconds) ||
        !_within(settings.rounds, ProgramLimits.rounds) ||
        !_within(settings.cycles, ProgramLimits.cycles) ||
        !_within(
          settings.restBetweenCyclesSeconds,
          ProgramLimits.restBetweenCyclesSeconds,
        )) {
      issues.add(ProgramIssue.invalidInterval);
    }
  }
  return issues;
}

/// Prépare un programme vide au format demandé.
Program newProgram({required String id, required ProgramFormat format}) {
  return Program(
    id: id,
    name: '',
    format: format,
    interval: format == ProgramFormat.interval
        ? IntervalSettings.defaults()
        : null,
  );
}

/// Change le format d'un programme : les paramètres des exercices sont
/// remis aux valeurs par défaut du nouveau format.
Program changeFormat(
  Program program,
  ProgramFormat format,
  Map<String, Exercise> exercisesById,
) {
  if (program.format == format) return program;
  return program.copyWith(
    format: format,
    interval: format == ProgramFormat.interval
        ? (program.interval ?? IntervalSettings.defaults())
        : null,
    items: [
      for (final item in program.items)
        if (exercisesById[item.exerciseId] case final exercise?)
          ProgramItem.defaultsFor(exercise, format),
    ],
  );
}

/// Durée estimée d'une répétition, pour l'estimation d'une séance.
const _secondsPerRep = 3;

/// Durée estimée de la séance ; `null` si elle dépend d'une distance.
Duration? estimateDuration(Program program) {
  var seconds = 0;
  switch (program.format) {
    case ProgramFormat.strength:
      for (final item in program.items) {
        final sets = item.sets ?? 0;
        final effort = item.reps != null
            ? item.reps! * _secondsPerRep
            : item.durationSeconds ?? 0;
        final rest = item.restSeconds ?? 0;
        seconds += sets * effort + (sets > 0 ? (sets - 1) * rest : 0);
      }
    case ProgramFormat.cardio:
      for (final item in program.items) {
        if (item.distanceMeters != null) return null;
        seconds += item.durationSeconds ?? 0;
      }
    case ProgramFormat.mobility:
      for (final item in program.items) {
        seconds += item.holdSeconds ?? 0;
      }
    case ProgramFormat.interval:
      final s = program.interval;
      if (s == null) return Duration.zero;
      final cycle = s.rounds * (s.workSeconds + s.restSeconds);
      seconds = s.cycles * cycle + (s.cycles - 1) * s.restBetweenCyclesSeconds;
  }
  return Duration(seconds: seconds);
}
