import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/demo/design_system_demo_page.dart';
import 'package:arise/core/design_system/widgets/rank_badge.dart';
import 'package:arise/core/design_system/widgets/system_window.dart';
import 'package:arise/core/design_system/widgets/xp_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('présente toutes les sections du design system', (tester) async {
    await tester.pumpApp(const DesignSystemDemoPage());

    for (final title in [
      'Couleurs',
      'Typographie',
      'Boutons',
      'Cadres',
      'Progression',
      'Rangs',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 300);
      expect(find.text(title), findsOneWidget);
    }

    await tester.scrollUntilVisible(find.byType(RankBadge).last, 300);
    expect(find.byType(RankBadge), findsNWidgets(RankId.values.length));

    await tester.scrollUntilVisible(find.byType(XpBar), -300);
    expect(find.byType(XpBar), findsOneWidget);

    await tester.scrollUntilVisible(find.byType(SystemWindow), -300);
    expect(find.byType(SystemWindow), findsOneWidget);
  });

  testWidgets('respecte les consignes d’accessibilité Flutter', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(const DesignSystemDemoPage());

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
