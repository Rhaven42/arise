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

/// Exercices créés par le joueur, stockés en JSON.
@DataClassName('CustomExerciseRow')
class CustomExercises extends Table {
  TextColumn get id => text()();

  TextColumn get json => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Programmes d'entraînement, stockés en JSON.
@DataClassName('ProgramRow')
class Programs extends Table {
  TextColumn get id => text()();

  TextColumn get json => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Séances planifiées, stockées en JSON.
@DataClassName('PlannedSessionRow')
class PlannedSessions extends Table {
  TextColumn get id => text()();

  /// Programme utilisé (dupliqué hors JSON pour les suppressions en cascade).
  TextColumn get programId => text()();

  TextColumn get json => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Séances réalisées, stockées en JSON.
@DataClassName('CompletedSessionRow')
class CompletedSessions extends Table {
  TextColumn get id => text()();

  /// Début de la séance (UTC), dupliqué hors JSON pour le tri.
  DateTimeColumn get startedAt => dateTime()();

  TextColumn get json => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Progression du joueur (une seule ligne, `id` = 1), stockée en JSON.
@DataClassName('ProgressionRow')
class ProgressionStates extends Table {
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
/// - v2 (phase 1) : ajout de `player_profiles` ;
/// - v3 (phase 2) : ajout de `custom_exercises`, `programs` et
///   `planned_sessions` ;
/// - v4 (phase 3) : ajout de `completed_sessions` ;
/// - v5 (phase 4) : ajout de `progression_states` ;
/// - v6 (phase 6A) : ajout de `character_sheets` ;
/// - v7 (phase 7) : ajout de `inventory_states` ;
/// - v8 (phase 8A) : ajout de `quest_states` et `trial_states`.
@DataClassName('CharacterSheetRow')
class CharacterSheets extends Table {
  IntColumn get id => integer()();

  TextColumn get json => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Inventaire du joueur (une seule ligne, `id` = 1), stocké en JSON.
@DataClassName('InventoryRow')
class InventoryStates extends Table {
  IntColumn get id => integer()();

  TextColumn get json => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Quête quotidienne en cours (une seule ligne, `id` = 1), en JSON.
@DataClassName('QuestRow')
class QuestStates extends Table {
  IntColumn get id => integer()();

  TextColumn get json => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Historique des épreuves de rang (une seule ligne, `id` = 1), en JSON.
@DataClassName('TrialRow')
class TrialStates extends Table {
  IntColumn get id => integer()();

  TextColumn get json => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    PendingSessions,
    LocalDrafts,
    PlayerProfiles,
    CustomExercises,
    Programs,
    PlannedSessions,
    CompletedSessions,
    ProgressionStates,
    CharacterSheets,
    InventoryStates,
    QuestStates,
    TrialStates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Identifiant unique de la ligne de profil.
  static const profileRowId = 1;

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(playerProfiles);
      }
      if (from < 3) {
        await migrator.createTable(customExercises);
        await migrator.createTable(programs);
        await migrator.createTable(plannedSessions);
      }
      if (from < 4) {
        await migrator.createTable(completedSessions);
      }
      if (from < 5) {
        await migrator.createTable(progressionStates);
      }
      if (from < 6) {
        await migrator.createTable(characterSheets);
      }
      if (from < 7) {
        await migrator.createTable(inventoryStates);
      }
      if (from < 8) {
        await migrator.createTable(questStates);
        await migrator.createTable(trialStates);
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

  /// Efface toutes les données du joueur.
  Future<void> eraseAll() {
    return transaction(() async {
      await delete(trialStates).go();
      await delete(questStates).go();
      await delete(inventoryStates).go();
      await delete(characterSheets).go();
      await delete(progressionStates).go();
      await delete(completedSessions).go();
      await delete(plannedSessions).go();
      await delete(programs).go();
      await delete(customExercises).go();
      await delete(playerProfiles).go();
      await delete(localDrafts).go();
      await delete(pendingSessions).go();
    });
  }

  // --- Exercices personnalisés -------------------------------------------

  Stream<List<String>> watchCustomExerciseJson() {
    final query = select(customExercises)
      ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]);
    return query.watch().map((rows) => [for (final r in rows) r.json]);
  }

  Future<List<String>> readCustomExerciseJson() async => [
    for (final r in await select(customExercises).get()) r.json,
  ];

  Future<void> saveCustomExerciseJson(
    String id,
    String json, {
    required DateTime updatedAt,
  }) {
    return into(customExercises).insertOnConflictUpdate(
      CustomExercisesCompanion.insert(
        id: id,
        json: json,
        updatedAt: updatedAt.toUtc(),
      ),
    );
  }

  Future<void> deleteCustomExercise(String id) =>
      (delete(customExercises)..where((t) => t.id.equals(id))).go();

  // --- Programmes ----------------------------------------------------------

  Stream<List<String>> watchProgramJson() {
    final query = select(programs)
      ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]);
    return query.watch().map((rows) => [for (final r in rows) r.json]);
  }

  Future<List<String>> readProgramJson() async => [
    for (final r in await select(programs).get()) r.json,
  ];

  Future<void> saveProgramJson(
    String id,
    String json, {
    required DateTime updatedAt,
  }) {
    return into(programs).insertOnConflictUpdate(
      ProgramsCompanion.insert(
        id: id,
        json: json,
        updatedAt: updatedAt.toUtc(),
      ),
    );
  }

  /// Supprime un programme et les séances planifiées qui l'utilisent.
  Future<void> deleteProgram(String id) {
    return transaction(() async {
      await (delete(
        plannedSessions,
      )..where((t) => t.programId.equals(id))).go();
      await (delete(programs)..where((t) => t.id.equals(id))).go();
    });
  }

  // --- Progression -------------------------------------------------------

  Stream<String?> watchProgressionJson() {
    final query = select(progressionStates)
      ..where((t) => t.id.equals(profileRowId));
    return query.watchSingleOrNull().map((row) => row?.json);
  }

  Future<String?> readProgressionJson() async {
    final query = select(progressionStates)
      ..where((t) => t.id.equals(profileRowId));
    return (await query.getSingleOrNull())?.json;
  }

  Future<void> saveProgressionJson(String json, {required DateTime updatedAt}) {
    return into(progressionStates).insertOnConflictUpdate(
      ProgressionStatesCompanion(
        id: const Value(profileRowId),
        json: Value(json),
        updatedAt: Value(updatedAt.toUtc()),
      ),
    );
  }

  // --- Personnage ---------------------------------------------------------

  Stream<String?> watchCharacterJson() {
    final query = select(characterSheets)
      ..where((t) => t.id.equals(profileRowId));
    return query.watchSingleOrNull().map((row) => row?.json);
  }

  Future<String?> readCharacterJson() async {
    final query = select(characterSheets)
      ..where((t) => t.id.equals(profileRowId));
    return (await query.getSingleOrNull())?.json;
  }

  Future<void> saveCharacterJson(String json, {required DateTime updatedAt}) {
    return into(characterSheets).insertOnConflictUpdate(
      CharacterSheetsCompanion(
        id: const Value(profileRowId),
        json: Value(json),
        updatedAt: Value(updatedAt.toUtc()),
      ),
    );
  }

  // --- Inventaire ----------------------------------------------------------

  Stream<String?> watchInventoryJson() {
    final query = select(inventoryStates)
      ..where((t) => t.id.equals(profileRowId));
    return query.watchSingleOrNull().map((row) => row?.json);
  }

  Future<String?> readInventoryJson() async {
    final query = select(inventoryStates)
      ..where((t) => t.id.equals(profileRowId));
    return (await query.getSingleOrNull())?.json;
  }

  Future<void> saveInventoryJson(String json, {required DateTime updatedAt}) {
    return into(inventoryStates).insertOnConflictUpdate(
      InventoryStatesCompanion(
        id: const Value(profileRowId),
        json: Value(json),
        updatedAt: Value(updatedAt.toUtc()),
      ),
    );
  }

  /// Lit progression et inventaire, applique [change] puis enregistre les
  /// deux ensemble : un achat ne peut jamais débiter sans livrer.
  Future<T> updateProgressionAndInventory<T>(
    Future<({String? progression, String inventory, T result})> Function(
      String? progression,
      String? inventory,
    )
    change, {
    required DateTime updatedAt,
  }) {
    return transaction(() async {
      final next = await change(
        await readProgressionJson(),
        await readInventoryJson(),
      );
      final progression = next.progression;
      if (progression != null) {
        await saveProgressionJson(progression, updatedAt: updatedAt);
      }
      await saveInventoryJson(next.inventory, updatedAt: updatedAt);
      return next.result;
    });
  }

  // --- Quêtes et épreuves ------------------------------------------------

  Stream<String?> watchQuestJson() {
    final query = select(questStates)..where((t) => t.id.equals(profileRowId));
    return query.watchSingleOrNull().map((row) => row?.json);
  }

  Future<String?> readQuestJson() async {
    final query = select(questStates)..where((t) => t.id.equals(profileRowId));
    return (await query.getSingleOrNull())?.json;
  }

  Future<void> saveQuestJson(String json, {required DateTime updatedAt}) {
    return into(questStates).insertOnConflictUpdate(
      QuestStatesCompanion(
        id: const Value(profileRowId),
        json: Value(json),
        updatedAt: Value(updatedAt.toUtc()),
      ),
    );
  }

  /// Ligne des quêtes au-delà du jour (semaine, donjon, événements).
  static const questBoardRowId = 2;

  Future<String?> readQuestBoardJson() async {
    final query = select(questStates)
      ..where((t) => t.id.equals(questBoardRowId));
    return (await query.getSingleOrNull())?.json;
  }

  Future<void> saveQuestBoardJson(String json, {required DateTime updatedAt}) {
    return into(questStates).insertOnConflictUpdate(
      QuestStatesCompanion(
        id: const Value(questBoardRowId),
        json: Value(json),
        updatedAt: Value(updatedAt.toUtc()),
      ),
    );
  }

  Stream<String?> watchTrialsJson() {
    final query = select(trialStates)..where((t) => t.id.equals(profileRowId));
    return query.watchSingleOrNull().map((row) => row?.json);
  }

  Future<String?> readTrialsJson() async {
    final query = select(trialStates)..where((t) => t.id.equals(profileRowId));
    return (await query.getSingleOrNull())?.json;
  }

  Future<void> saveTrialsJson(String json, {required DateTime updatedAt}) {
    return into(trialStates).insertOnConflictUpdate(
      TrialStatesCompanion(
        id: const Value(profileRowId),
        json: Value(json),
        updatedAt: Value(updatedAt.toUtc()),
      ),
    );
  }

  /// Enregistre ensemble, dans une seule transaction, les états du jeu
  /// modifiés par une récompense (`null` = inchangé) : une quête ou une
  /// épreuve ne peut jamais être marquée sans sa récompense, ni l'inverse.
  Future<void> saveGameState({
    required DateTime updatedAt,
    String? progression,
    String? inventory,
    String? quest,
    String? questBoard,
    String? trials,
  }) {
    return transaction(() async {
      if (progression != null) {
        await saveProgressionJson(progression, updatedAt: updatedAt);
      }
      if (inventory != null) {
        await saveInventoryJson(inventory, updatedAt: updatedAt);
      }
      if (quest != null) await saveQuestJson(quest, updatedAt: updatedAt);
      if (questBoard != null) {
        await saveQuestBoardJson(questBoard, updatedAt: updatedAt);
      }
      if (trials != null) await saveTrialsJson(trials, updatedAt: updatedAt);
    });
  }

  // --- Séances réalisées -------------------------------------------------

  Stream<List<String>> watchCompletedSessionJson() {
    final query = select(completedSessions)
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]);
    return query.watch().map((rows) => [for (final r in rows) r.json]);
  }

  Future<List<String>> readCompletedSessionJson() async {
    final query = select(completedSessions)
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]);
    return [for (final r in await query.get()) r.json];
  }

  Future<void> saveCompletedSessionJson(
    String id, {
    required DateTime startedAt,
    required String json,
  }) {
    return into(completedSessions).insertOnConflictUpdate(
      CompletedSessionsCompanion.insert(
        id: id,
        startedAt: startedAt.toUtc(),
        json: json,
      ),
    );
  }

  // --- Séances planifiées ------------------------------------------------

  Stream<List<String>> watchPlannedSessionJson() {
    final query = select(plannedSessions)
      ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]);
    return query.watch().map((rows) => [for (final r in rows) r.json]);
  }

  Future<List<String>> readPlannedSessionJson() async => [
    for (final r in await select(plannedSessions).get()) r.json,
  ];

  Future<void> savePlannedSessionJson(
    String id, {
    required String programId,
    required String json,
    required DateTime updatedAt,
  }) {
    return into(plannedSessions).insertOnConflictUpdate(
      PlannedSessionsCompanion.insert(
        id: id,
        programId: programId,
        json: json,
        updatedAt: updatedAt.toUtc(),
      ),
    );
  }

  Future<void> deletePlannedSession(String id) =>
      (delete(plannedSessions)..where((t) => t.id.equals(id))).go();

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
