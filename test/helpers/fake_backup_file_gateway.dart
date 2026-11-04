import 'package:arise/features/backup/domain/backup_file_gateway.dart';

/// Faux échanges de fichiers : mémorise les partages, renvoie un contenu
/// choisi par le test.
class FakeBackupFileGateway implements BackupFileGateway {
  FakeBackupFileGateway({this.fileToPick, this.shareSucceeds = true});

  /// Contenu renvoyé par [pickTextFile] (`null` = sélection annulée).
  String? fileToPick;
  bool shareSucceeds;

  final shared = <({String fileName, String content})>[];

  @override
  Future<bool> share({
    required String fileName,
    required String content,
  }) async {
    shared.add((fileName: fileName, content: content));
    return shareSucceeds;
  }

  @override
  Future<String?> pickTextFile() async => fileToPick;
}
