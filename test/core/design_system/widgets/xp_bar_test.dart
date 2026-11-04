import 'package:arise/core/design_system/widgets/xp_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  test('la progression est bornée entre 0 et 1', () {
    expect(const XpBar(current: 0, goal: 100).progress, 0);
    expect(const XpBar(current: 25, goal: 100).progress, 0.25);
    expect(const XpBar(current: 250, goal: 100).progress, 1);
  });

  testWidgets('affiche la progression et une description accessible', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(const XpBar(current: 63, goal: 180));

    expect(find.text('63 / 180 XP'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(XpBar)),
      matchesSemantics(label: 'Expérience : 63 sur 180', value: '35 %'),
    );
    handle.dispose();
  });

  testWidgets('reste lisible avec une grande taille de police', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpApp(
      const Padding(
        padding: EdgeInsets.all(16),
        child: XpBar(current: 63, goal: 180),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('63 / 180 XP'), findsOneWidget);
  });
}
