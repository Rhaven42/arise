import 'dart:io';
import 'dart:typed_data';

import 'package:arise/features/avatar/domain/snapshot_sharer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Écrit l'image dans le dossier temporaire puis ouvre la feuille de partage.
class PlatformSnapshotSharer implements SnapshotSharer {
  const PlatformSnapshotSharer();

  @override
  Future<bool> sharePng(Uint8List png, {required String fileName}) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(png, flush: true);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        fileNameOverrides: [fileName],
      ),
    );
    return result.status == ShareResultStatus.success;
  }
}
