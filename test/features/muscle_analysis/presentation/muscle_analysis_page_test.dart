import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';
import 'package:arise/features/workout_player/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

CompletedSession _pushSession() => CompletedSession(
  id: 's1',
  programName: 'Poussée',
  format: ProgramFormat.strength,
  startedAt: testNow,
  endedAt: testNow.add(const Duration(minutes: 20)),
  sets: [
    for (var i = 0; i < 4; i++)
      const CompletedSet(
        exerciseId: 'push_up',
        activeSeconds: 40,
        reps: 10,
        rpe: 7,
      ),
  ],
  activeSeconds: 160,
  xpEarned: 40,
  completed: true,
);

Future<void> _scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('sans séance, la carte reste vide et sans conseil', (
    tester,
  ) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.analysis);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Analyse musculaire'), findsOneWidget);
    expect(find.text('Semaine'), findsOneWidget);
    expect(find.text('Aucune séance sur cette période.'), findsWidgets);
    await _scrollTo(tester, find.text('Conseils du Système'));
    expect(find.textContaining('Déséquilibre'), findsNothing);
    await tester.unmountApp();
  });

  testWidgets('une séance de pompes colore les pectoraux et alerte', (
    tester,
  ) async {
    final container = createTestContainer();
    await container
        .read(completedSessionRepositoryProvider)
        .save(_pushSession());
    await tester.openWithProfile(container, AppRoutes.analysis);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('1 séance sur cette période.'), findsOneWidget);
    await _scrollTo(tester, find.textContaining('la poussée'));
    expect(find.textContaining('la poussée'), findsOneWidget);
    await _scrollTo(tester, find.text('Conseils du Système'));
    await _scrollTo(tester, find.textContaining('en retard, essaie'));
    expect(find.textContaining('en retard, essaie'), findsWidgets);
    await _scrollTo(tester, find.text('Détail par muscle'));
    expect(find.text('Détail par muscle'), findsOneWidget);
    await tester.unmountApp();
  });

  testWidgets('la semaine précédente est vide, la suivante est bloquée', (
    tester,
  ) async {
    final container = createTestContainer();
    await container
        .read(completedSessionRepositoryProvider)
        .save(_pushSession());
    await tester.openWithProfile(container, AppRoutes.analysis);
    await tester.pump(const Duration(milliseconds: 300));

    final next = find.byTooltip('Période suivante');
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(of: next, matching: find.byType(IconButton)).first,
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Période précédente'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Aucune séance sur cette période.'), findsWidgets);

    await tester.tap(find.text('Année'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1 séance sur cette période.'), findsOneWidget);
    await tester.unmountApp();
  });
}
