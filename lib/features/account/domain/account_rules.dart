import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/account/domain/account.dart';

/// Nom de la base des installations antérieures aux comptes : elle devient
/// le premier compte, sans déplacer aucun fichier.
const String legacyDatabaseName = 'arise';

/// Nom de la base d'un nouveau compte.
String databaseNameFor(String accountId) => 'arise_$accountId';

/// Motif de refus d'un pseudo.
enum AccountNameIssue { empty, tooLong, taken, tooMany }

/// Vérifie un pseudo : non vide, assez court, pas déjà pris (sans tenir
/// compte des majuscules) par un autre compte que [exceptId].
AccountNameIssue? accountNameIssue(
  String name,
  Iterable<Account> accounts, {
  String? exceptId,
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return AccountNameIssue.empty;
  if (trimmed.length > gameConfig.account.nameMaxLength) {
    return AccountNameIssue.tooLong;
  }
  final lower = trimmed.toLowerCase();
  final taken = accounts.any(
    (a) => a.id != exceptId && a.name.trim().toLowerCase() == lower,
  );
  return taken ? AccountNameIssue.taken : null;
}

/// Vrai si [pin] est un code PIN valide (chiffres, longueur configurée).
bool isValidPin(String pin) =>
    pin.length == gameConfig.account.pinLength &&
    pin.codeUnits.every((c) => c >= 0x30 && c <= 0x39);

/// Vrai si un nouveau compte peut encore être créé.
bool canCreateAccount(Iterable<Account> accounts) =>
    accounts.length < gameConfig.account.maxAccounts;

/// Comptes du plus récemment utilisé au plus ancien.
List<Account> sortedByLastUse(Iterable<Account> accounts) =>
    [...accounts]..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));

/// Empreinte d'un code PIN (fournie par la couche données).
abstract interface class PinHasher {
  /// Nouveau sel aléatoire.
  String newSalt();

  String hash(String pin, String salt);
}

/// Vrai si [pin] ouvre [account] (toujours vrai sans code PIN).
bool pinMatches(Account account, String pin, PinHasher hasher) {
  final hash = account.pinHash;
  final salt = account.pinSalt;
  if (hash == null || salt == null) return true;
  return hasher.hash(pin, salt) == hash;
}
