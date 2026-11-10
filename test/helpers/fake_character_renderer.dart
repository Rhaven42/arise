import 'dart:typed_data';

import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/domain/character_scene.dart';
import 'package:arise/features/avatar/domain/snapshot_sharer.dart';
import 'package:arise/features/avatar/presentation/character_renderer.dart';
import 'package:flutter/widgets.dart';

/// Rendu factice pour les tests : affiche l'identifiant du modèle, garde la
/// dernière apparence et la dernière scène, et fournit une capture fixe.
class FakeCharacterRenderer implements CharacterRenderer {
  CharacterAppearance? last;
  CharacterScene? lastScene;

  /// Image renvoyée par les captures.
  static final Uint8List png = Uint8List.fromList([137, 80, 78, 71]);

  @override
  Widget build({
    required CharacterAppearance appearance,
    CharacterScene scene = const CharacterScene(),
    CharacterSnapshotController? snapshots,
    Key? key,
  }) {
    last = appearance;
    lastScene = scene;
    snapshots?.handler = () async => png;
    return Center(key: key, child: Text('rendu:${appearance.modelId}'));
  }
}

/// Partage factice : garde les images reçues.
class FakeSnapshotSharer implements SnapshotSharer {
  final List<({Uint8List png, String fileName})> shared = [];

  @override
  Future<bool> sharePng(Uint8List png, {required String fileName}) async {
    shared.add((png: png, fileName: fileName));
    return true;
  }
}
