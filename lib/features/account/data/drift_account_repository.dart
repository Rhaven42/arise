import 'package:arise/core/database/accounts_database.dart';
import 'package:arise/features/account/domain/account.dart';
import 'package:arise/features/account/domain/account_repository.dart';
import 'package:drift/drift.dart';

/// Registre des comptes stocké dans la base `accounts`.
class DriftAccountRepository implements AccountRepository {
  DriftAccountRepository(this._db);

  final AccountsDatabase _db;

  static const _activeKey = 'active_account';

  @override
  Future<List<Account>> readAll() async {
    final rows = await _db.select(_db.accounts).get();
    return [
      for (final row in rows)
        Account(
          id: row.id,
          name: row.name,
          databaseName: row.databaseName,
          pinHash: row.pinHash,
          pinSalt: row.pinSalt,
          createdAt: row.createdAt,
          lastUsedAt: row.lastUsedAt,
        ),
    ];
  }

  @override
  Future<String?> readActiveId() async {
    final query = _db.select(_db.accountSettings)
      ..where((t) => t.settingKey.equals(_activeKey));
    return (await query.getSingleOrNull())?.value;
  }

  @override
  Future<void> save(Account account) async {
    await _db
        .into(_db.accounts)
        .insertOnConflictUpdate(
          AccountsCompanion.insert(
            id: account.id,
            name: account.name,
            databaseName: account.databaseName,
            pinHash: Value(account.pinHash),
            pinSalt: Value(account.pinSalt),
            createdAt: account.createdAt.toUtc(),
            lastUsedAt: account.lastUsedAt.toUtc(),
          ),
        );
  }

  @override
  Future<void> setActive(String accountId) async {
    await _db
        .into(_db.accountSettings)
        .insertOnConflictUpdate(
          AccountSettingsCompanion.insert(
            settingKey: _activeKey,
            value: accountId,
          ),
        );
  }

  @override
  Future<void> delete(String accountId) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.accounts,
      )..where((t) => t.id.equals(accountId))).go();
      if (await readActiveId() == accountId) {
        await (_db.delete(
          _db.accountSettings,
        )..where((t) => t.settingKey.equals(_activeKey))).go();
      }
    });
  }
}
