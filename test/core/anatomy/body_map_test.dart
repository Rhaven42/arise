import 'dart:io';

import 'package:arise/core/anatomy/body_map.dart';
import 'package:arise/core/anatomy/body_shapes.dart';
import 'package:arise/core/anatomy/body_shapes_provider.dart';
import 'package:arise/core/anatomy/muscle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/provider_app.dart';

BodyShapes _load(BodyView view) => BodyShapesParser.parse(
  File(bodyShapeAssets[view]!).readAsStringSync(),
  view,
);

void main() {
  test('chaque zone se retrouve au toucher en son centre', () {
    for (final view in BodyView.values) {
      final shapes = _load(view);
      final painter = BodyMapPainter(shapes: shapes, highlights: const {});
      final size = Size(shapes.width * 2, shapes.height * 2);
      for (final entry in shapes.zones.entries) {
        final center = pathFrom(entry.value.first).getBounds().center;
        expect(
          painter.muscleAt(center * 2, size),
          entry.key,
          reason: entry.key.key,
        );
      }
    }
  });

  testWidgets('toucher une zone renvoie le muscle', (tester) async {
    final shapes = _load(BodyView.front);
    final container = ProviderContainer.test(
      overrides: [
        bodyShapesProvider.overrideWith((_) async => {BodyView.front: shapes}),
      ],
    );
    final tapped = <MuscleId>[];
    await tester.pumpWithContainer(
      container,
      Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            height: 450,
            child: BodyMap(
              view: BodyView.front,
              highlights: const {MuscleId.quadriceps: MuscleRole.primary},
              semanticLabel: 'Silhouette',
              onMuscleTap: tapped.add,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final origin = tester.getTopLeft(find.byType(CustomPaint).last);
    final center = pathFrom(shapes.zones[MuscleId.quadriceps]!.first)
        .getBounds()
        .center;
    await tester.tapAt(origin + center);

    expect(tapped, [MuscleId.quadriceps]);
  });
}
