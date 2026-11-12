import 'package:arise/features/account/domain/account.dart';
import 'package:arise/features/account/domain/account_repository.dart';
import 'package:arise/features/account/domain/account_rules.dart';

/// Registre de comptes en mémoire.
class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository({List<Account> accounts = const [], this.activeId})
    : _accounts = {for (final a in accounts) a.id: a};

  final Map<String, Account> _accounts;
  String? activeId;

  @override
  Future<List<Account>> readAll() async => _accounts.values.toList();

  @override
  Future<String?> readActiveId() async => activeId;

  @override
  Future<void> save(Account account) async => _accounts[account.id] = account;

  @override
  Future<void> setActive(String accountId) async => activeId = accountId;

  @override
  Future<void> delete(String accountId) async {
    _accounts.remove(accountId);
    if (activeId == accountId) activeId = null;
  }
}

/// Fichiers de bases simulés.
class FakeAccountStorage implements AccountStorage {
  FakeAccountStorage({Set<String>? existing}) : existing = existing ?? {};

  final Set<String> existing;
  final List<String> deleted = [];

  @override
  Future<bool> exists(String databaseName) async =>
      existing.contains(databaseName);

  @override
  Future<void> delete(String databaseName) async {
    existing.remove(databaseName);
    deleted.add(databaseName);
  }
}

/// Empreinte lisible et instantanée (les tests n'ont pas besoin de SHA-256).
class FakePinHasher implements PinHasher {
  @override
  String newSalt() => 'sel';

  @override
  String hash(String pin, String salt) => '$salt:$pin';
}

/// Compte ouvert par défaut dans les tests.
Account testAccount({String id = 'test', String name = 'Testeur'}) => Account(
  id: id,
  name: name,
  databaseName: databaseNameFor(id),
  createdAt: DateTime.utc(2026, 11),
  lastUsedAt: DateTime.utc(2026, 11),
);
