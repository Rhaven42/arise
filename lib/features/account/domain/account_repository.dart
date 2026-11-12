import 'package:arise/features/account/domain/account.dart';

/// Registre des comptes locaux et du compte actif.
abstract interface class AccountRepository {
  Future<List<Account>> readAll();

  /// Identifiant du compte actif, ou `null` s'il n'y en a pas encore.
  Future<String?> readActiveId();

  Future<void> save(Account account);

  Future<void> setActive(String accountId);

  Future<void> delete(String accountId);
}

/// Fichiers des bases de jeu des comptes.
abstract interface class AccountStorage {
  /// Vrai si la base [databaseName] existe sur le téléphone.
  Future<bool> exists(String databaseName);

  /// Supprime la base [databaseName].
  Future<void> delete(String databaseName);
}
