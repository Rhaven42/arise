import 'package:arise/core/database/accounts_database.dart';
import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/account/data/account_bootstrap.dart';
import 'package:arise/features/account/data/account_files.dart';
import 'package:arise/features/account/data/drift_account_repository.dart';
import 'package:arise/features/account/data/sha256_pin_hasher.dart';
import 'package:arise/features/account/domain/account.dart';
import 'package:arise/features/account/domain/account_repository.dart';
import 'package:arise/features/account/domain/account_rules.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_providers.g.dart';

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) =>
    DriftAccountRepository(ref.watch(accountsDatabaseProvider));

@Riverpod(keepAlive: true)
AccountStorage accountStorage(Ref ref) => const FileAccountStorage();

@Riverpod(keepAlive: true)
PinHasher pinHasher(Ref ref) => Sha256PinHasher();

/// Comptes du téléphone, compte actif et état du verrou (code PIN).
class AccountsView {
  const AccountsView({
    required this.accounts,
    required this.active,
    required this.unlocked,
  });

  /// Du plus récemment utilisé au plus ancien.
  final List<Account> accounts;
  final Account? active;

  /// Faux tant que le code PIN du compte actif n'a pas été saisi.
  final bool unlocked;

  bool get locked => !unlocked;
}

/// Gestion des comptes locaux.
@Riverpod(keepAlive: true)
class AccountsController extends _$AccountsController {
  AccountRepository get _repository => ref.read(accountRepositoryProvider);
  DateTime _now() => ref.read(clockProvider)();

  @override
  Future<AccountsView> build() async {
    final snapshot = await loadAccounts(
      _repository,
      ref.read(accountStorageProvider),
      now: _now(),
    );
    final active = snapshot.active;
    _selectDatabase(active);
    return AccountsView(
      accounts: snapshot.accounts,
      active: active,
      unlocked: active == null || !active.hasPin,
    );
  }

  void _selectDatabase(Account? account) {
    if (ref.read(activeDatabaseNameProvider) != account?.databaseName) {
      ref
          .read(activeDatabaseNameProvider.notifier)
          .select(account?.databaseName);
    }
  }

  Future<void> _reload({required bool unlocked}) async {
    final accounts = sortedByLastUse(await _repository.readAll());
    final activeId = await _repository.readActiveId();
    Account? active;
    for (final account in accounts) {
      if (account.id == activeId) active = account;
    }
    _selectDatabase(active);
    state = AsyncData(
      AccountsView(accounts: accounts, active: active, unlocked: unlocked),
    );
  }

  /// Crée un compte et l'ouvre. Renvoie le motif du refus éventuel.
  Future<AccountNameIssue?> create(String name, {String? pin}) async {
    final accounts = (await future).accounts;
    final issue = accountNameIssue(name, accounts);
    if (issue != null) return issue;
    if (!canCreateAccount(accounts)) return AccountNameIssue.tooMany;
    final now = _now();
    final id = now.microsecondsSinceEpoch.toRadixString(36);
    await _repository.save(
      _withPin(
        Account(
          id: id,
          name: name.trim(),
          databaseName: databaseNameFor(id),
          createdAt: now,
          lastUsedAt: now,
        ),
        pin,
      ),
    );
    await _repository.setActive(id);
    await _reload(unlocked: true);
    return null;
  }

  Account _withPin(Account account, String? pin) {
    if (pin == null) return account.copyWith(pinHash: null, pinSalt: null);
    final hasher = ref.read(pinHasherProvider);
    final salt = hasher.newSalt();
    return account.copyWith(pinSalt: salt, pinHash: hasher.hash(pin, salt));
  }

  /// Ouvre un autre compte. Renvoie faux si le code PIN est faux.
  Future<bool> switchTo(String accountId, {String pin = ''}) async {
    final accounts = (await future).accounts;
    final account = accounts.firstWhere((a) => a.id == accountId);
    if (!pinMatches(account, pin, ref.read(pinHasherProvider))) return false;
    await _repository.save(account.copyWith(lastUsedAt: _now()));
    await _repository.setActive(account.id);
    await _reload(unlocked: true);
    return true;
  }

  /// Déverrouille le compte actif. Renvoie faux si le code PIN est faux.
  Future<bool> unlock(String pin) async {
    final view = await future;
    final active = view.active;
    if (active == null) return true;
    if (!pinMatches(active, pin, ref.read(pinHasherProvider))) return false;
    state = AsyncData(
      AccountsView(accounts: view.accounts, active: active, unlocked: true),
    );
    return true;
  }

  /// Renomme le compte actif. Renvoie le motif du refus éventuel.
  Future<AccountNameIssue?> rename(String name) async {
    final view = await future;
    final active = view.active;
    if (active == null) return AccountNameIssue.empty;
    final issue = accountNameIssue(name, view.accounts, exceptId: active.id);
    if (issue != null) return issue;
    await _repository.save(active.copyWith(name: name.trim()));
    await _reload(unlocked: view.unlocked);
    return null;
  }

  /// Définit (ou retire avec `null`) le code PIN du compte actif.
  Future<void> setPin(String? pin) async {
    final view = await future;
    final active = view.active;
    if (active == null) return;
    await _repository.save(_withPin(active, pin));
    await _reload(unlocked: view.unlocked);
  }

  /// Supprime un compte et toutes ses données. Sans compte actif ensuite,
  /// le joueur en choisit ou en crée un depuis l'écran titre.
  Future<void> delete(String accountId) async {
    final view = await future;
    final account = view.accounts.firstWhere((a) => a.id == accountId);
    await _repository.delete(accountId);
    await _reload(unlocked: view.unlocked || view.active?.id == accountId);
    await ref.read(accountStorageProvider).delete(account.databaseName);
  }
}
