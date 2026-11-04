import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/planning/domain/planned_session.dart';
import 'package:arise/features/planning/domain/program.dart';
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

    /// Ajouts du format v2 (phase 2) ; absents des fichiers v1.
    @Default([]) List<Exercise> customExercises,
    @Default([]) List<Program> programs,
    @Default([]) List<PlannedSession> plannedSessions,
  }) = _BackupData;

  factory BackupData.fromJson(Map<String, dynamic> json) =>
      _$BackupDataFromJson(json);
}
