import 'package:arise/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la migration v1 → v2 ajoute le profil sans perte', () async {
    // Base recréée dans l'état de la phase 0 (schéma v1) avant que Drift
    // n'applique ses migrations.
    final database = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw
          ..execute(
            'CREATE TABLE pending_sessions (id TEXT NOT NULL PRIMARY KEY, '
            'payload_json TEXT NOT NULL, created_at INTEGER NOT NULL, '
            'attempt_count INTEGER NOT NULL DEFAULT 0)',
          )
          ..execute(
            'CREATE TABLE local_drafts (draft_key TEXT NOT NULL PRIMARY KEY, '
            'json TEXT NOT NULL, updated_at INTEGER NOT NULL)',
          )
          ..execute("INSERT INTO local_drafts VALUES ('onboarding', '{}', 0)")
          ..userVersion = 1,
      ),
    );
    addTearDown(database.close);

    expect(await database.readDraft('onboarding'), '{}');
    expect(await database.readProfileJson(), isNull);
    await database.saveProfileJson(
      '{"ok":true}',
      updatedAt: DateTime.utc(2026),
    );
    expect(await database.readProfileJson(), '{"ok":true}');

    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.read<int>('user_version'), database.schemaVersion);
  });

  test(
    'la migration v2 → v3 ajoute les exercices, programmes et séances',
    () async {
      final database = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) => raw
            ..execute(
              'CREATE TABLE pending_sessions (id TEXT NOT NULL PRIMARY KEY, '
              'payload_json TEXT NOT NULL, created_at INTEGER NOT NULL, '
              'attempt_count INTEGER NOT NULL DEFAULT 0)',
            )
            ..execute(
              'CREATE TABLE local_drafts (draft_key TEXT NOT NULL PRIMARY KEY, '
              'json TEXT NOT NULL, updated_at INTEGER NOT NULL)',
            )
            ..execute(
              'CREATE TABLE player_profiles (id INTEGER NOT NULL PRIMARY KEY, '
              'json TEXT NOT NULL, updated_at INTEGER NOT NULL)',
            )
            ..execute(
              "INSERT INTO player_profiles VALUES (1, '{\"ok\":true}', 0)",
            )
            ..userVersion = 2,
        ),
      );
      addTearDown(database.close);

      expect(await database.readProfileJson(), '{"ok":true}');
      expect(await database.readProgramJson(), isEmpty);
      await database.saveProgramJson('p', '{}', updatedAt: DateTime.utc(2026));
      await database.savePlannedSessionJson(
        's',
        programId: 'p',
        json: '{}',
        updatedAt: DateTime.utc(2026),
      );
      await database.saveCustomExerciseJson(
        'c',
        '{}',
        updatedAt: DateTime.utc(2026),
      );
      expect(await database.readPlannedSessionJson(), ['{}']);
      expect(await database.readCustomExerciseJson(), ['{}']);

      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.read<int>('user_version'), database.schemaVersion);
    },
  );

  test(
    'la migration v3 → v4 ajoute les séances réalisées sans perte',
    () async {
      final database = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) => raw
            ..execute(
              'CREATE TABLE pending_sessions (id TEXT NOT NULL PRIMARY KEY, '
              'payload_json TEXT NOT NULL, created_at INTEGER NOT NULL, '
              'attempt_count INTEGER NOT NULL DEFAULT 0)',
            )
            ..execute(
              'CREATE TABLE local_drafts (draft_key TEXT NOT NULL PRIMARY KEY, '
              'json TEXT NOT NULL, updated_at INTEGER NOT NULL)',
            )
            ..execute(
              'CREATE TABLE player_profiles (id INTEGER NOT NULL PRIMARY KEY, '
              'json TEXT NOT NULL, updated_at INTEGER NOT NULL)',
            )
            ..execute(
              'CREATE TABLE custom_exercises (id TEXT NOT NULL PRIMARY KEY, '
              'json TEXT NOT NULL, updated_at INTEGER NOT NULL)',
            )
            ..execute(
              'CREATE TABLE programs (id TEXT NOT NULL PRIMARY KEY, '
              'json TEXT NOT NULL, updated_at INTEGER NOT NULL)',
            )
            ..execute(
              'CREATE TABLE planned_sessions (id TEXT NOT NULL PRIMARY KEY, '
              'program_id TEXT NOT NULL, json TEXT NOT NULL, '
              'updated_at INTEGER NOT NULL)',
            )
            ..execute("INSERT INTO programs VALUES ('p', '{}', 0)")
            ..userVersion = 3,
        ),
      );
      addTearDown(database.close);

      expect(await database.readProgramJson(), ['{}']);
      expect(await database.readCompletedSessionJson(), isEmpty);
      await database.saveCompletedSessionJson(
        'old',
        startedAt: DateTime.utc(2026),
        json: '{"n":1}',
      );
      await database.saveCompletedSessionJson(
        'new',
        startedAt: DateTime.utc(2026, 2),
        json: '{"n":2}',
      );
      // Les séances les plus récentes d'abord.
      expect(await database.readCompletedSessionJson(), ['{"n":2}', '{"n":1}']);

      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.read<int>('user_version'), database.schemaVersion);
    },
  );

  test('la migration v4 → v5 ajoute la progression sans perte', () async {
    final database = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw
          ..execute(
            'CREATE TABLE pending_sessions (id TEXT NOT NULL PRIMARY '
            'KEY, payload_json TEXT NOT NULL, created_at INTEGER NOT '
            'NULL, attempt_count INTEGER NOT NULL DEFAULT 0)',
          )
          ..execute(
            'CREATE TABLE local_drafts (draft_key TEXT NOT NULL PRIMARY '
            'KEY, json TEXT NOT NULL, updated_at INTEGER NOT NULL)',
          )
          ..execute(
            'CREATE TABLE player_profiles (id INTEGER NOT NULL PRIMARY '
            'KEY, json TEXT NOT NULL, updated_at INTEGER NOT NULL)',
          )
          ..execute(
            'CREATE TABLE custom_exercises (id TEXT NOT NULL PRIMARY '
            'KEY, json TEXT NOT NULL, updated_at INTEGER NOT NULL)',
          )
          ..execute(
            'CREATE TABLE programs (id TEXT NOT NULL PRIMARY KEY, json '
            'TEXT NOT NULL, updated_at INTEGER NOT NULL)',
          )
          ..execute(
            'CREATE TABLE planned_sessions (id TEXT NOT NULL PRIMARY '
            'KEY, program_id TEXT NOT NULL, json TEXT NOT NULL, '
            'updated_at INTEGER NOT NULL)',
          )
          ..execute(
            'CREATE TABLE completed_sessions (id TEXT NOT NULL PRIMARY '
            'KEY, started_at INTEGER NOT NULL, json TEXT NOT NULL)',
          )
          ..execute("INSERT INTO completed_sessions VALUES ('s', 0, '{}')")
          ..userVersion = 4,
      ),
    );
    addTearDown(database.close);

    expect(await database.readCompletedSessionJson(), ['{}']);
    expect(await database.readProgressionJson(), isNull);
    await database.saveProgressionJson(
      '{"level":2}',
      updatedAt: DateTime.utc(2026),
    );
    expect(await database.readProgressionJson(), '{"level":2}');

    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.read<int>('user_version'), 5);
  });
}
