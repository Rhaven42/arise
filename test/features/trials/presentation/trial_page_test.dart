import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/level_curve.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/features/trials/presentation/trial_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

ProgressionState _player({required int level, int strength = 20}) =>
    ProgressionState.initial(CivilDate.ofLocal(testNow)).copyWith(
      level: level,
      xpInLevel: level == 9 ? xpToNextLevel(9) : 0,
      allocatedStats: {StatId.strength: strength},
    );

AriseButton _fightButton(WidgetTester tester) =>
    tester.widget<AriseButton>(find.byKey(TrialPage.fightKey));

void main() {
  testWidgets('au dernier niveau du rang, le boss peut être affronté', (
    tester,
  ) async {
    final container = createTestContainer();
    await container.read(progressionRepositoryProvider).save(_player(level: 9));
    await tester.openWithProfile(container, AppRoutes.trial);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Le Gardien du Rocher'), findsOneWidget);
    expect(find.text('ÉPREUVE DE FORCE'), findsOneWidget);
    expect(find.textContaining('20 pompes puis 30 squats'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(TrialPage.fightKey),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(_fightButton(tester).onPressed, isNotNull);
    await tester.unmountApp();
  });

  testWidgets('trop tôt : le niveau requis est indiqué, bouton inactif', (
    tester,
  ) async {
    final container = createTestContainer();
    await container.read(progressionRepositoryProvider).save(_player(level: 3));
    await tester.openWithProfile(container, AppRoutes.trial);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.scrollUntilVisible(
      find.byKey(TrialPage.fightKey),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Atteins le niveau 9 pour affronter Le Gardien du Rocher.'),
      findsOneWidget,
    );
    expect(_fightButton(tester).onPressed, isNull);
    await tester.unmountApp();
  });
}
