import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/hero_class.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/progression/presentation/hero_class_page.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('au rang C, le chasseur choisit sa classe', (tester) async {
    final container = createTestContainer();
    await container
        .read(progressionRepositoryProvider)
        .save(
          ProgressionState.initial(CivilDate.ofLocal(testNow))
              .copyWith(level: 20, defeatedBosses: {RankId.e, RankId.d}),
        );
    await tester.openWithProfile(container, AppRoutes.heroClass);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Aucune classe choisie.'), findsOneWidget);
    final select = find.byKey(HeroClassPage.selectKey(HeroClass.ranger));
    await tester.scrollUntilVisible(
      select,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(select);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tu es désormais Ranger.'), findsOneWidget);
    final saved = await container.read(progressionRepositoryProvider).read();
    expect(saved?.heroClass, HeroClass.ranger);
    // Un seul changement par mois : les autres classes sont verrouillées.
    final tank = find.byKey(HeroClassPage.selectKey(HeroClass.tank));
    await tester.scrollUntilVisible(
      tank,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<AriseButton>(tank).onPressed, isNull);
    await tester.unmountApp();
  });
}
