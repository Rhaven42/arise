import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';
import 'package:arise/features/workout_player/domain/completed_session_repository.dart';

/// Séances réalisées stockées dans la base locale.
class DriftCompletedSessionRepository implements CompletedSessionRepository {
  const DriftCompletedSessionRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<CompletedSession>> watchAll() => _database
      .watchCompletedSessionJson()
      .map((rows) => [for (final json in rows) decode(json)]);

  @override
  Future<List<CompletedSession>> readAll() async => [
    for (final json in await _database.readCompletedSessionJson()) decode(json),
  ];

  @override
  Future<void> save(CompletedSession session) =>
      _database.saveCompletedSessionJson(
        session.id,
        startedAt: session.startedAt,
        json: jsonEncode(session.toJson()),
      );

  static CompletedSession decode(String json) =>
      CompletedSession.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
