import 'dart:io';

import 'package:arise/features/account/domain/account_repository.dart';
import 'package:path_provider/path_provider.dart';

/// Fichiers des bases de jeu, dans le dossier où drift_flutter les range
/// (`<documents>/<nom>.sqlite`).
abstract final class AccountFiles {
  static Future<File> _file(String databaseName, [String suffix = '']) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$databaseName.sqlite$suffix');
  }

  /// Vrai si la base existe déjà sur le téléphone.
  static Future<bool> exists(String databaseName) async =>
      (await _file(databaseName)).existsSync();

  /// Supprime la base d'un compte et ses fichiers de journal.
  static Future<void> delete(String databaseName) async {
    for (final suffix in const ['', '-wal', '-shm', '-journal']) {
      final file = await _file(databaseName, suffix);
      if (file.existsSync()) await file.delete();
    }
  }
}

/// Accès aux fichiers des bases des comptes.
class FileAccountStorage implements AccountStorage {
  const FileAccountStorage();

  @override
  Future<bool> exists(String databaseName) => AccountFiles.exists(databaseName);

  @override
  Future<void> delete(String databaseName) => AccountFiles.delete(databaseName);
}
