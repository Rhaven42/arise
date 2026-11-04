import 'package:arise/core/anatomy/body_shapes.dart';
import 'package:arise/core/anatomy/muscle.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'body_shapes_provider.g.dart';

/// Chemins des silhouettes embarquées.
const Map<BodyView, String> bodyShapeAssets = {
  BodyView.front: 'assets/svg/body_front.svg',
  BodyView.back: 'assets/svg/body_back.svg',
};

/// Silhouettes face et dos, chargées une seule fois.
@Riverpod(keepAlive: true)
Future<Map<BodyView, BodyShapes>> bodyShapes(Ref ref) async {
  return {
    for (final entry in bodyShapeAssets.entries)
      entry.key: BodyShapesParser.parse(
        await rootBundle.loadString(entry.value),
        entry.key,
      ),
  };
}
