import 'package:arise/features/backup/domain/backup_data.dart';

/// Lecture, restauration et effacement de toutes les données locales.
abstract interface class BackupRepository {
  /// Photographie des données actuelles, prête à être exportée.
  Future<BackupData> snapshot(DateTime now);

  /// Remplace intégralement les données locales par la sauvegarde.
  Future<void> restore(BackupData data);

  /// Efface toutes les données du joueur.
  Future<void> eraseAll();
}
