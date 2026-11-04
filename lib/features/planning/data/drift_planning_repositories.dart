import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/planning/domain/planned_session.dart';
import 'package:arise/features/planning/domain/planning_repositories.dart';
import 'package:arise/features/planning/domain/program.dart';

/// Programmes stockés dans la base locale.
class DriftProgramRepository implements ProgramRepository {
  const DriftProgramRepository(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  @override
  Stream<List<Program>> watchAll() => _database.watchProgramJson().map(
    (rows) => [for (final json in rows) decodeProgram(json)],
  );

  @override
  Future<void> save(Program program) => _database.saveProgramJson(
    program.id,
    jsonEncode(program.toJson()),
    updatedAt: _clock(),
  );

  @override
  Future<void> delete(String id) => _database.deleteProgram(id);

  static Program decodeProgram(String json) =>
      Program.fromJson(jsonDecode(json) as Map<String, dynamic>);
}

/// Séances planifiées stockées dans la base locale.
class DriftPlanningRepository implements PlanningRepository {
  const DriftPlanningRepository(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  @override
  Stream<List<PlannedSession>> watchAll() => _database
      .watchPlannedSessionJson()
      .map((rows) => [for (final json in rows) decodeSession(json)]);

  @override
  Future<void> save(PlannedSession session) => _database.savePlannedSessionJson(
    session.id,
    programId: session.programId,
    json: jsonEncode(session.toJson()),
    updatedAt: _clock(),
  );

  @override
  Future<void> delete(String id) => _database.deletePlannedSession(id);

  static PlannedSession decodeSession(String json) =>
      PlannedSession.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
