import 'package:arise/features/health/domain/health_repository.dart';
import 'package:arise/features/health/domain/health_rules.dart';

/// Faux service de santé : lectures préparées par jour (date locale), sans
/// jamais toucher au téléphone.
class FakeHealthSource implements HealthSource {
  FakeHealthSource({this.granted = true, Map<DateTime, HealthReading>? days})
    : days = days ?? {};

  bool granted;
  bool fails = false;
  final Map<DateTime, HealthReading> days;
  int authorizeCalls = 0;

  @override
  Future<bool> authorize() async {
    authorizeCalls++;
    return granted;
  }

  @override
  Future<HealthReading> read(DateTime start, DateTime end) async {
    if (fails) throw Exception('lecture impossible');
    return days[start] ??
        (steps: 0, activities: const <TimeSpan>[], sleepMinutes: 0);
  }
}
