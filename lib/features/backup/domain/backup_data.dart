import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'backup_data.freezed.dart';
part 'backup_data.g.dart';

/// Contenu d'un fichier de sauvegarde ARISE.
@freezed
abstract class BackupData with _$BackupData {
  const factory BackupData({
    required String format,
    required int version,
    required DateTime exportedAt,
    PlayerProfile? profile,
  }) = _BackupData;

  factory BackupData.fromJson(Map<String, dynamic> json) =>
      _$BackupDataFromJson(json);
}
