import 'package:arise/features/account/domain/account.dart';
import 'package:arise/features/account/domain/account_repository.dart';
import 'package:arise/features/account/domain/account_rules.dart';

/// Comptes connus et compte actif au démarrage.
typedef AccountsSnapshot = ({List<Account> accounts, Account? active});

/// Charge le registre. Au premier lancement après l'arrivée des comptes, la
/// base existante devient le premier compte (sans pseudo, à nommer) : la
/// progression du joueur est conservée telle quelle.
Future<AccountsSnapshot> loadAccounts(
  AccountRepository repository,
  AccountStorage storage, {
  required DateTime now,
}) async {
  var accounts = await repository.readAll();
  if (accounts.isEmpty && await storage.exists(legacyDatabaseName)) {
    final legacy = Account(
      id: 'legacy',
      name: '',
      databaseName: legacyDatabaseName,
      createdAt: now,
      lastUsedAt: now,
    );
    await repository.save(legacy);
    await repository.setActive(legacy.id);
    accounts = [legacy];
  }
  final activeId = await repository.readActiveId();
  Account? active;
  for (final account in accounts) {
    if (account.id == activeId) active = account;
  }
  return (accounts: sortedByLastUse(accounts), active: active);
}
