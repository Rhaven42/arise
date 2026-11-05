import 'dart:typed_data';

/// Partage d'une capture du personnage (image PNG) par la feuille de
/// partage du téléphone : c'est l'utilisateur qui choisit la destination.
abstract interface class SnapshotSharer {
  /// Renvoie `true` si le partage a abouti.
  Future<bool> sharePng(Uint8List png, {required String fileName});
}
