import 'dart:convert';

import 'package:arise/features/backup/domain/backup_data.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/planning/domain/planned_session.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/profile/domain/player_profile.dart';

/// Raison du refus d'un fichier de sauvegarde.
enum BackupError {
  /// Le fichier n'est pas du JSON lisible.
  unreadable,

  /// Le fichier n'est pas une sauvegarde ARISE.
  notArise,

  /// Sauvegarde créée par une version plus récente de l'application.
  tooRecent,

  /// Sauvegarde ARISE mais contenu invalide.
  corrupted,
}

/// Erreur levée par [BackupCodec.decode].
class InvalidBackupException implements Exception {
  const InvalidBackupException(this.error);

  final BackupError error;

  @override
  String toString() => 'InvalidBackupException(${error.name})';
}

/// Lecture et écriture du format de sauvegarde (JSON versionné).
abstract final class BackupCodec {
  static const format = 'arise-backup';

  /// Version courante du format ; les versions antérieures restent lisibles.
  ///
  /// - v1 (phase 1) : profil ;
  /// - v2 (phase 2) : exercices personnalisés, programmes et planning.
  static const currentVersion = 2;

  /// Construit une sauvegarde au format courant.
  static BackupData create({
    required DateTime exportedAt,
    required PlayerProfile? profile,
    List<Exercise> customExercises = const [],
    List<Program> programs = const [],
    List<PlannedSession> plannedSessions = const [],
  }) {
    return BackupData(
      format: format,
      version: currentVersion,
      exportedAt: exportedAt.toUtc(),
      profile: profile,
      customExercises: customExercises,
      programs: programs,
      plannedSessions: plannedSessions,
    );
  }

  static String encode(BackupData data) =>
      const JsonEncoder.withIndent('  ').convert(data.toJson());

  /// Décode et valide un fichier de sauvegarde.
  ///
  /// Lève [InvalidBackupException] si le contenu est refusé.
  static BackupData decode(String content) {
    final Object? json;
    try {
      json = jsonDecode(content);
    } on FormatException {
      throw const InvalidBackupException(BackupError.unreadable);
    }
    if (json is! Map<String, dynamic> || json['format'] != format) {
      throw const InvalidBackupException(BackupError.notArise);
    }
    final version = json['version'];
    if (version is! int || version < 1) {
      throw const InvalidBackupException(BackupError.corrupted);
    }
    if (version > currentVersion) {
      throw const InvalidBackupException(BackupError.tooRecent);
    }
    try {
      return BackupData.fromJson(json);
    } on Object {
      throw const InvalidBackupException(BackupError.corrupted);
    }
  }

  /// Nom de fichier proposé à l'export, par exemple
  /// `arise-sauvegarde-2026-11-04.json`.
  static String fileName(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    final local = date.toLocal();
    return 'arise-sauvegarde-${local.year}-${two(local.month)}-'
        '${two(local.day)}.json';
  }
}
