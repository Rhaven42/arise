import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/achievements/presentation/achievements_page.dart';
import 'package:arise/features/achievements/presentation/achievements_providers.dart';
import 'package:arise/features/achievements/presentation/hunter_panel.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';
import 'package:arise/features/workout_player/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

final CompletedSession _session = CompletedSession(
  id: 'first',
  programName: 'test',
  format: ProgramFormat.strength,
  startedAt: testNow.subtract(const Duration(hours: 1)),
  endedAt: testNow,
  sets: const [
    CompletedSet(exerciseId: 'squat', activeSeconds: 60, reps: 12, rpe: 8),
  ],
  activeSeconds: 600,
  xpEarned: 10,
  completed: true,
);

void main() {
  testWidgets('la page rattrape les hauts faits et masque les secrets', (
    tester,
  ) async {
    final container = createTestContainer();
    await container.read(completedSessionRepositoryProvider).save(_session);
    await tester.openWithProfile(container, AppRoutes.achievements);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final state = await container.read(achievementsStateProvider.future);
    expect(state.unlocked.keys, contains('first_session'));
    expect(find.text('Premier pas'), findsOneWidget);
    expect(find.textContaining('Obtenu le'), findsOneWidget);
    expect(find.textContaining('hauts faits'), findsWidgets);

    // Les secrets restent masqués.
    await tester.scrollUntilVisible(
      find.byKey(AchievementsPage.tileKey('shadow_army')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Haut fait secret'), findsWidgets);
    expect(find.text('Armée des Ombres'), findsNothing);
    await tester.unmountApp();
  });

  testWidgets('le panneau des exploits mène aux hauts faits', (tester) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.systemHome);
    await tester.scrollUntilVisible(
      find.byKey(HunterPanel.achievementsKey),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(HunterPanel.achievementsKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AchievementsPage), findsOneWidget);
    await tester.unmountApp();
  });
}
