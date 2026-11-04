import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/rank_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('affiche la lettre du rang et son nom accessible', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(const RankBadge(rank: RankId.c));

    expect(find.text('C'), findsOneWidget);
    expect(find.bySemanticsLabel('Rang C'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('affiche une couronne pour le rang Monarque', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(const RankBadge(rank: RankId.monarch));

    expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
    expect(find.bySemanticsLabel('Rang Monarque'), findsOneWidget);
    handle.dispose();
  });

  test('chaque rang a une couleur distincte', () {
    final colors = {for (final rank in RankId.values) RankBadge.colorOf(rank)};
    expect(colors, hasLength(RankId.values.length));
  });
}
