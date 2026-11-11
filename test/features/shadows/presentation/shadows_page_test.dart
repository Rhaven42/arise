import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/features/shadows/presentation/shadows_page.dart';
import 'package:arise/features/shadows/presentation/shadows_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('rang C : les Ombres ne sont pas encore éveillées', (
    tester,
  ) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.shadows);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Les Ombres s’éveillent au rang B.'), findsOneWidget);
    await tester.unmountApp();
  });

  testWidgets('le boss du rang B offre une Ombre à extraire', (tester) async {
    final container = createTestContainer();
    await container
        .read(progressionRepositoryProvider)
        .save(
          ProgressionState.initial(CivilDate.ofLocal(testNow)).copyWith(
            level: 50,
            defeatedBosses: {RankId.e, RankId.d, RankId.c, RankId.b},
          ),
        );
    await tester.openWithProfile(container, AppRoutes.shadows);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Ombres à extraire'), findsOneWidget);
    expect(find.text('Ombre du Colosse de Basalte'), findsOneWidget);
    await tester.tap(find.byKey(ShadowsPage.extractKey('boss_b')));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final state = await container.read(shadowsStateProvider.future);
    expect(state.shadows.single.id, 'boss_b');
    expect(state.active, ['boss_b']);
    expect(find.byKey(ShadowsPage.toggleKey('boss_b')), findsOneWidget);
    expect(find.textContaining('Ombres actives : 1 / 5'), findsOneWidget);

    // Mise au repos.
    await tester.tap(find.byKey(ShadowsPage.toggleKey('boss_b')));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect((await container.read(shadowsStateProvider.future)).active, isEmpty);
    await tester.unmountApp();
  });
}
