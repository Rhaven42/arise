import 'package:arise/features/health/domain/health_repository.dart';
import 'package:arise/features/health/domain/health_rules.dart';
import 'package:health/health.dart';

/// Health Connect (Android) et Santé d'Apple (iOS), en lecture seule.
class PlatformHealthSource implements HealthSource {
  PlatformHealthSource() : _health = Health();

  final Health _health;
  bool _configured = false;

  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.WORKOUT,
    HealthDataType.SLEEP_SESSION,
  ];

  /// Activités qui rapportent de l'Endurance.
  static const Set<HealthWorkoutActivityType> _activities = {
    HealthWorkoutActivityType.WALKING,
    HealthWorkoutActivityType.RUNNING,
    HealthWorkoutActivityType.BIKING,
    HealthWorkoutActivityType.HIKING,
  };

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<bool> authorize() async {
    try {
      await _configure();
      if (!await _health.isHealthConnectAvailable()) return false;
      return await _health.requestAuthorization(
        _types,
        permissions: [for (final _ in _types) HealthDataAccess.READ],
      );
    } on Exception {
      return false;
    }
  }

  @override
  Future<HealthReading> read(DateTime start, DateTime end) async {
    await _configure();
    final steps = await _health.getTotalStepsInInterval(start, end) ?? 0;
    final points = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.WORKOUT, HealthDataType.SLEEP_SESSION],
      startTime: start,
      endTime: end,
    );
    final activities = <TimeSpan>[];
    var sleep = Duration.zero;
    for (final p in points) {
      if (p.type == HealthDataType.SLEEP_SESSION) {
        sleep += p.dateTo.difference(p.dateFrom);
      } else if (p.value case final WorkoutHealthValue w
          when _activities.contains(w.workoutActivityType)) {
        activities.add((start: p.dateFrom, end: p.dateTo));
      }
    }
    return (
      steps: steps,
      activities: activities,
      sleepMinutes: sleep.inMinutes,
    );
  }
}
