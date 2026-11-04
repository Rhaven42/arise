import 'package:arise/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  group('séances en attente', () {
    test('sont restituées de la plus ancienne à la plus récente', () async {
      await database.enqueuePendingSession(
        id: 'b',
        payloadJson: '{"n":2}',
        createdAt: DateTime.utc(2026, 1, 2),
      );
      await database.enqueuePendingSession(
        id: 'a',
        payloadJson: '{"n":1}',
        createdAt: DateTime.utc(2026),
      );

      final pending = await database.pendingSessionsInOrder();

      expect([for (final s in pending) s.id], ['a', 'b']);
      expect(pending.first.attemptCount, 0);
    });

    test('comptent les tentatives puis disparaissent après envoi', () async {
      await database.enqueuePendingSession(
        id: 's1',
        payloadJson: '{}',
        createdAt: DateTime.utc(2026),
      );

      await database.markSessionAttempt('s1');
      await database.markSessionAttempt('s1');
      expect((await database.pendingSessionsInOrder()).single.attemptCount, 2);

      await database.removePendingSession('s1');
      expect(await database.pendingSessionsInOrder(), isEmpty);
    });
  });

  group('profil', () {
    test('est enregistré, remplacé et diffusé', () async {
      final emissions = database.watchProfileJson();
      final expectation = expectLater(
        emissions,
        emitsInOrder([isNull, '{"v":1}', '{"v":2}']),
      );

      await pumpEventQueue();
      await database.saveProfileJson(
        '{"v":1}',
        updatedAt: DateTime.utc(2026),
      );
      await pumpEventQueue();
      await database.saveProfileJson(
        '{"v":2}',
        updatedAt: DateTime.utc(2026),
      );
      await expectation;
    });

    test('eraseAll efface profil, brouillons et séances', () async {
      await database.saveProfileJson('{}', updatedAt: DateTime.utc(2026));
      await database.saveDraft(
        key: 'k',
        json: '{}',
        updatedAt: DateTime.utc(2026),
      );
      await database.enqueuePendingSession(
        id: 's',
        payloadJson: '{}',
        createdAt: DateTime.utc(2026),
      );

      await database.eraseAll();

      expect(await database.readProfileJson(), isNull);
      expect(await database.readDraft('k'), isNull);
      expect(await database.pendingSessionsInOrder(), isEmpty);
    });
  });

  group('brouillons', () {
    test('sont enregistrés, remplacés puis supprimés', () async {
      expect(await database.readDraft('character'), isNull);

      await database.saveDraft(
        key: 'character',
        json: '{"v":1}',
        updatedAt: DateTime.utc(2026),
      );
      await database.saveDraft(
        key: 'character',
        json: '{"v":2}',
        updatedAt: DateTime.utc(2026, 1, 2),
      );
      expect(await database.readDraft('character'), '{"v":2}');

      await database.deleteDraft('character');
      expect(await database.readDraft('character'), isNull);
    });
  });
}
