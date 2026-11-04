import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/planning/domain/program_rules.dart';
import 'package:arise/l10n/generated/app_localizations.dart';

/// Libellés traduits du planning.
extension PlanningLabels on AppLocalizations {
  String format(ProgramFormat format) => programFormat(format.name);

  /// Durée lisible : « 45 s », « 12 min », « 1 h 05 ».
  String duration(Duration duration) {
    final minutes = duration.inMinutes;
    if (duration.inSeconds < 60) return durationSeconds(duration.inSeconds);
    if (minutes < 60) return durationMinutes(minutes);
    return durationHours(
      minutes ~/ 60,
      (minutes % 60).toString().padLeft(2, '0'),
    );
  }

  String distance(int meters) => meters >= 1000
      ? distanceKilometers(
          (meters / 1000).toStringAsFixed(meters % 1000 == 0 ? 0 : 1),
        )
      : distanceMeters(meters);

  /// Heure lisible à partir d'une minute de la journée : « 18:30 ».
  String timeOfDay(int minuteOfDay) =>
      '${(minuteOfDay ~/ 60).toString().padLeft(2, '0')}:'
      '${(minuteOfDay % 60).toString().padLeft(2, '0')}';

  String programIssue(ProgramIssue issue) => switch (issue) {
    ProgramIssue.nameTooShort => programNameTooShort(ProgramLimits.nameMin),
    ProgramIssue.nameTooLong => programNameTooLong(ProgramLimits.nameMax),
    ProgramIssue.noExercise => programNoExercise,
    ProgramIssue.invalidSets ||
    ProgramIssue.invalidReps ||
    ProgramIssue.invalidDuration ||
    ProgramIssue.invalidDistance ||
    ProgramIssue.invalidLoad ||
    ProgramIssue.invalidRest ||
    ProgramIssue.invalidHold ||
    ProgramIssue.invalidInterval => programInvalidValues,
  };
}
