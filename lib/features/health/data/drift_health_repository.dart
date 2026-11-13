import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/health/domain/health_log.dart';
import 'package:arise/features/health/domain/health_repository.dart';

/// Historique santé stocké dans la base locale (JSON).
class DriftHealthRepository implements HealthRepository {
  const DriftHealthRepository(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  @override
  Future<HealthLog> read() async => decode(await _database.readHealthJson());

  @override
  Future<void> save(HealthLog log) =>
      _database.saveHealthJson(jsonEncode(log.toJson()), updatedAt: _clock());

  /// Historique décodé (vide quand rien n'est encore enregistré).
  static HealthLog decode(String? json) => json == null
      ? const HealthLog()
      : HealthLog.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
