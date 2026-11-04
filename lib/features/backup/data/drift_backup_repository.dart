import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/backup/domain/backup_codec.dart';
import 'package:arise/features/backup/domain/backup_data.dart';
import 'package:arise/features/backup/domain/backup_repository.dart';
import 'package:arise/features/profile/domain/player_profile.dart';

/// Sauvegarde et restauration à partir de la base locale.
class DriftBackupRepository implements BackupRepository {
  const DriftBackupRepository(this._database);

  final AppDatabase _database;

  @override
  Future<BackupData> snapshot(DateTime now) async {
    final json = await _database.readProfileJson();
    final profile = json == null
        ? null
        : PlayerProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
    return BackupCodec.create(exportedAt: now, profile: profile);
  }

  @override
  Future<void> restore(BackupData data) {
    return _database.transaction(() async {
      await _database.eraseAll();
      final profile = data.profile;
      if (profile != null) {
        await _database.saveProfileJson(
          jsonEncode(profile.toJson()),
          updatedAt: DateTime.now(),
        );
      }
    });
  }

  @override
  Future<void> eraseAll() => _database.eraseAll();
}
