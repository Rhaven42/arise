/// Échanges de fichiers avec le système (partage, sélection).
abstract interface class BackupFileGateway {
  /// Propose le fichier via la feuille de partage du téléphone.
  ///
  /// Renvoie `true` si l'utilisateur a mené le partage à son terme.
  Future<bool> share({required String fileName, required String content});

  /// Laisse l'utilisateur choisir un fichier et renvoie son contenu texte,
  /// ou `null` s'il a annulé.
  Future<String?> pickTextFile();
}
