import 'package:arise/features/health/domain/health_log.dart';
import 'package:arise/features/health/domain/health_rules.dart';

/// Historique santé enregistré sur le téléphone.
abstract interface class HealthRepository {
  Future<HealthLog> read();

  Future<void> save(HealthLog log);
}

/// Lecture d'une journée sur le téléphone (Health Connect, Santé d'Apple).
typedef HealthReading = ({
  int steps,
  List<TimeSpan> activities,
  int sleepMinutes,
});

/// Source des données de santé : lecture seule, jamais d'écriture.
abstract interface class HealthSource {
  /// Demande l'autorisation de lecture. Renvoie faux si elle est refusée ou
  /// si le téléphone n'a pas de service de santé.
  Future<bool> authorize();

  /// Pas, activités (marche, course, vélo) et sommeil entre [start] et
  /// [end] (le sommeil compté est celui qui se termine dans la plage).
  Future<HealthReading> read(DateTime start, DateTime end);
}
