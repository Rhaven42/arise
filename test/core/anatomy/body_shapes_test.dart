import 'dart:io';

import 'package:arise/core/anatomy/body_shapes.dart';
import 'package:arise/core/anatomy/body_shapes_provider.dart';
import 'package:arise/core/anatomy/muscle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('silhouettes SVG', () {
    for (final view in BodyView.values) {
      test('la vue ${view.name} contient exactement ses muscles', () {
        final svg = File(bodyShapeAssets[view]!).readAsStringSync();
        final shapes = BodyShapesParser.parse(svg, view);

        expect(shapes.zones.keys.toSet(), {
          for (final m in MuscleId.values)
            if (m.view == view) m,
        });
        expect(shapes.outline, isNotEmpty);
        for (final paths in shapes.zones.values) {
          expect(paths, isNotEmpty);
        }
      });
    }
  });

  group('parsePathData', () {
    test('décode les commandes M, L, C et Z', () {
      final data = BodyShapesParser.parsePathData('M1 2 L3.5 4 C1 2 3 4 5 6 Z');
      expect([for (final c in data) c.op], ['M', 'L', 'C', 'Z']);
      expect(data[2].args, [1, 2, 3, 4, 5, 6]);
    });

    test('refuse une commande inconnue ou incomplète', () {
      expect(
        () => BodyShapesParser.parsePathData('Q1 2'),
        throwsA(isA<BodyShapesFormatException>()),
      );
      expect(
        () => BodyShapesParser.parsePathData('C1 2 3'),
        throwsA(isA<BodyShapesFormatException>()),
      );
    });
  });

  test('refuse un muscle inconnu', () {
    const svg =
        '<svg viewBox="0 0 10 10"><path id="outline" d="M0 0 Z"/>'
        '<g id="nope"><path d="M0 0 Z"/></g></svg>';
    expect(
      () => BodyShapesParser.parse(svg, BodyView.front),
      throwsA(isA<BodyShapesFormatException>()),
    );
  });
}
