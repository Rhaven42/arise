import 'dart:typed_data';

import 'package:arise/features/avatar/data/platform_snapshot_sharer.dart';
import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/domain/character_scene.dart';
import 'package:arise/features/avatar/domain/snapshot_sharer.dart';
import 'package:arise/features/avatar/presentation/webview_character_renderer.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'character_renderer.g.dart';

/// Affiche un personnage, quel que soit le moteur (WebGL embarqué
/// aujourd'hui, Unity ou Godot plus tard). Aucun type de moteur n'apparaît
/// dans cette interface.
abstract interface class CharacterRenderer {
  Widget build({
    required CharacterAppearance appearance,
    CharacterScene scene = const CharacterScene(),
    CharacterSnapshotController? snapshots,
    Key? key,
  });
}

/// Demande une capture (PNG) au rendu auquel il est attaché.
class CharacterSnapshotController {
  /// Branché par le moteur de rendu (`null` quand il est détaché).
  Future<Uint8List?> Function()? handler;

  /// Image PNG de la vue actuelle, ou `null` si le rendu n'est pas prêt.
  Future<Uint8List?> capture() async => await handler?.call();
}

/// Moteur de rendu utilisé par l'application (remplacé dans les tests).
@Riverpod(keepAlive: true)
CharacterRenderer characterRenderer(Ref ref) =>
    const WebViewCharacterRenderer();

/// Partage des captures (remplacé dans les tests).
@Riverpod(keepAlive: true)
SnapshotSharer snapshotSharer(Ref ref) => const PlatformSnapshotSharer();
