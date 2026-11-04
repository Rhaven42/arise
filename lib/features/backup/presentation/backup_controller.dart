import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/backup/data/drift_backup_repository.dart';
import 'package:arise/features/backup/data/platform_backup_file_gateway.dart';
import 'package:arise/features/backup/domain/backup_codec.dart';
import 'package:arise/features/backup/domain/backup_data.dart';
import 'package:arise/features/backup/domain/backup_file_gateway.dart';
import 'package:arise/features/backup/domain/backup_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_controller.g.dart';

@Riverpod(keepAlive: true)
BackupRepository backupRepository(Ref ref) {
  return DriftBackupRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
BackupFileGateway backupFileGateway(Ref ref) {
  return const PlatformBackupFileGateway();
}

/// Résultat de la lecture d'un fichier de sauvegarde.
sealed class BackupPickResult {
  const BackupPickResult();
}

/// L'utilisateur a fermé le sélecteur sans choisir de fichier.
final class BackupPickCancelled extends BackupPickResult {
  const BackupPickCancelled();
}

/// Le fichier choisi a été refusé.
final class BackupPickInvalid extends BackupPickResult {
  const BackupPickInvalid(this.error);

  final BackupError error;
}

/// Sauvegarde valide, prête à être restaurée après confirmation.
final class BackupPickReady extends BackupPickResult {
  const BackupPickReady(this.data);

  final BackupData data;
}

/// Actions de sauvegarde, de restauration et d'effacement.
@Riverpod(keepAlive: true)
class BackupController extends _$BackupController {
  @override
  void build() {}

  /// Exporte toutes les données ; renvoie `true` si le partage a abouti.
  Future<bool> exportBackup() async {
    final now = ref.read(clockProvider)();
    final data = await ref.read(backupRepositoryProvider).snapshot(now);
    final shared = await ref
        .read(backupFileGatewayProvider)
        .share(
          fileName: BackupCodec.fileName(now),
          content: BackupCodec.encode(data),
        );
    return shared;
  }

  /// Laisse choisir un fichier et le valide, sans rien modifier.
  Future<BackupPickResult> pickBackup() async {
    final content = await ref.read(backupFileGatewayProvider).pickTextFile();
    if (content == null) return const BackupPickCancelled();
    try {
      return BackupPickReady(BackupCodec.decode(content));
    } on InvalidBackupException catch (exception) {
      return BackupPickInvalid(exception.error);
    }
  }

  Future<void> restore(BackupData data) =>
      ref.read(backupRepositoryProvider).restore(data);

  Future<void> eraseAll() => ref.read(backupRepositoryProvider).eraseAll();
}
