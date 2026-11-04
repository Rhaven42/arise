import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.g.dart';

/// Séances enregistrées hors ligne, en attente d'envoi au serveur.
class PendingSessions extends Table {
  TextColumn get id => text()();

  /// Contenu de la séance, sérialisé en JSON.
  TextColumn get payloadJson => text()();

  DateTimeColumn get createdAt => dateTime()();

  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Brouillons locaux (personnage en cours de création, formulaires…).
class LocalDrafts extends Table {
  TextColumn get draftKey => text()();

  TextColumn get json => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {draftKey};
}

/// Profil du joueur (une seule ligne, `id` = 1), stocké en JSON.
@DataClassName('PlayerProfileRow')
class PlayerProfiles extends Table {
  IntColumn get id => integer()();

  TextColumn get json => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Base locale SQLite (Drift) de l'application.
///
/// Historique du schéma :
/// - v1 (phase 0) : `pending_sessions`, `local_drafts` ;
/// - v2 (phase 1) : ajout de `player_profiles`.
@DriftDatabase(tables: [PendingSessions, LocalDrafts, PlayerProfiles])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Identifiant unique de la ligne de profil.
  static const profileRowId = 1;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(playerProfiles);
      }
    },
  );

  /// Profil sérialisé en JSON, émis à chaque changement.
  Stream<String?> watchProfileJson() {
    final query = select(playerProfiles)
      ..where((t) => t.id.equals(profileRowId));
    return query.watchSingleOrNull().map((row) => row?.json);
  }

  Future<String?> readProfileJson() async {
    final query = select(playerProfiles)
      ..where((t) => t.id.equals(profileRowId));
    return (await query.getSingleOrNull())?.json;
  }

  Future<void> saveProfileJson(String json, {required DateTime updatedAt}) {
    return into(playerProfiles).insertOnConflictUpdate(
      PlayerProfilesCompanion(
        id: const Value(profileRowId),
        json: Value(json),
        updatedAt: Value(updatedAt.toUtc()),
      ),
    );
  }

  /// Efface toutes les données du joueur (profil, brouillons, séances).
  Future<void> eraseAll() {
    return transaction(() async {
      await delete(playerProfiles).go();
      await delete(localDrafts).go();
      await delete(pendingSessions).go();
    });
  }

  /// Ajoute une séance à la file d'attente de synchronisation.
  Future<void> enqueuePendingSession({
    required String id,
    required String payloadJson,
    required DateTime createdAt,
  }) {
    return into(pendingSessions).insert(
      PendingSessionsCompanion.insert(
        id: id,
        payloadJson: payloadJson,
        createdAt: createdAt.toUtc(),
      ),
    );
  }

  /// Séances en attente, de la plus ancienne à la plus récente.
  Future<List<PendingSession>> pendingSessionsInOrder() {
    final query = select(pendingSessions)
      ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]);
    return query.get();
  }

  /// Incrémente le compteur de tentatives d'envoi d'une séance.
  Future<void> markSessionAttempt(String id) async {
    await customUpdate(
      'UPDATE pending_sessions SET attempt_count = attempt_count + 1 '
      'WHERE id = ?',
      variables: [Variable.withString(id)],
      updates: {pendingSessions},
    );
  }

  /// Retire une séance de la file une fois acceptée par le serveur.
  Future<void> removePendingSession(String id) async {
    await (delete(pendingSessions)..where((t) => t.id.equals(id))).go();
  }

  /// Enregistre ou remplace un brouillon.
  Future<void> saveDraft({
    required String key,
    required String json,
    required DateTime updatedAt,
  }) async {
    await into(localDrafts).insertOnConflictUpdate(
      LocalDraftsCompanion.insert(
        draftKey: key,
        json: json,
        updatedAt: updatedAt.toUtc(),
      ),
    );
  }

  /// Lit un brouillon, ou `null` s'il n'existe pas.
  Future<String?> readDraft(String key) async {
    final query = select(localDrafts)..where((t) => t.draftKey.equals(key));
    final row = await query.getSingleOrNull();
    return row?.json;
  }

  Future<void> deleteDraft(String key) async {
    await (delete(localDrafts)..where((t) => t.draftKey.equals(key))).go();
  }
}

/// Base locale unique de l'application.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final database = AppDatabase(driftDatabase(name: 'arise'));
  ref.onDispose(() => unawaited(database.close()));
  return database;
}
