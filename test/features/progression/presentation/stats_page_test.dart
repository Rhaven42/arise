import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/features/progression/presentation/stats_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('les stats se détaillent et les points libres se placent', (
    tester,
  ) async {
    final container = createTestContainer();
    await container
        .read(progressionRepositoryProvider)
        .save(
          ProgressionState.initial(CivilDate.ofLocal(testNow)).copyWith(
            level: 1,
            freeStatPoints: 1,
            statXp: {StatId.endurance: 20},
          ),
        );
    await tester.openWithProfile(container, AppRoutes.stats);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(StatsPage), findsOneWidget);
    expect(find.text('1 point à placer'), findsOneWidget);
    expect(find.text('Prochain point gagné : 20 / 50 XP'), findsOneWidget);

    await tester.tap(find.byKey(StatsPage.allocateKey(StatId.strength)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Aucun point à placer'), findsOneWidget);
    expect(find.byKey(StatsPage.allocateKey(StatId.agility)), findsNothing);
    final saved = await container.read(progressionRepositoryProvider).read();
    expect(saved?.stat(StatId.strength), 1);

    expect(find.text('Placés : 1 · Gagnés : 0'), findsOneWidget);

    // La Volonté s'explique sans jauge d'XP.
    await tester.scrollUntilVisible(
      find.text('Gagnée par la régularité, jamais par un exercice.'),
      200,
    );
    await tester.unmountApp();
  });
}
