import 'package:arise/core/database/accounts_database.dart';
import 'package:arise/features/account/data/account_bootstrap.dart';
import 'package:arise/features/account/data/drift_account_repository.dart';
import 'package:arise/features/account/data/sha256_pin_hasher.dart';
import 'package:arise/features/account/domain/account_rules.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_accounts.dart';

void main() {
  late AccountsDatabase db;
  late DriftAccountRepository repository;

  setUp(() {
    db = AccountsDatabase(NativeDatabase.memory());
    repository = DriftAccountRepository(db);
  });
  tearDown(() => db.close());

  test('le registre enregistre, active et supprime les comptes', () async {
    await repository.save(testAccount(id: 'a', name: 'Aelin'));
    await repository.save(
      testAccount(id: 'b', name: 'Rowan').copyWith(pinHash: 'h', pinSalt: 's'),
    );
    await repository.setActive('b');
    expect(await repository.readActiveId(), 'b');
    final all = await repository.readAll();
    expect(all.map((a) => a.name), containsAll(['Aelin', 'Rowan']));
    expect(all.firstWhere((a) => a.id == 'b').hasPin, isTrue);

    await repository.delete('b');
    expect(await repository.readActiveId(), isNull);
    expect((await repository.readAll()).single.id, 'a');
  });

  test('la base d’avant les comptes devient le premier compte', () async {
    final storage = FakeAccountStorage(existing: {legacyDatabaseName});
    final now = DateTime.utc(2026, 11, 12);
    final snapshot = await loadAccounts(repository, storage, now: now);
    expect(snapshot.active?.databaseName, legacyDatabaseName);
    expect(snapshot.active?.name, isEmpty);
    // Une seule fois : le lancement suivant relit le même compte.
    final again = await loadAccounts(repository, storage, now: now);
    expect(again.accounts, hasLength(1));
  });

  test('installation neuve : aucun compte ouvert', () async {
    final snapshot = await loadAccounts(
      repository,
      FakeAccountStorage(),
      now: DateTime.utc(2026, 11, 12),
    );
    expect(snapshot.accounts, isEmpty);
    expect(snapshot.active, isNull);
  });

  test('empreinte du code PIN salée et stable', () {
    final hasher = Sha256PinHasher();
    final salt = hasher.newSalt();
    expect(hasher.hash('1234', salt), hasher.hash('1234', salt));
    expect(hasher.hash('1234', salt), isNot(hasher.hash('1235', salt)));
    expect(hasher.hash('1234', salt), isNot(hasher.hash('1234', 'autre')));
    expect(hasher.newSalt(), isNot(salt));
  });
}
