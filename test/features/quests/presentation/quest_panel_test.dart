import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/quests/presentation/quest_panel.dart';
import 'package:arise/features/quests/presentation/quests_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('un jour d’entraînement, la quête du jour est proposée', (
    tester,
  ) async {
    // Jeudi : jour d'entraînement du profil de test.
    final container = createTestContainer(
      clock: () => DateTime(2026, 11, 5, 10),
    );
    await tester.openWithProfile(container, AppRoutes.systemHome);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.scrollUntilVisible(
      find.byKey(QuestPanel.startKey),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Quête du jour'), findsOneWidget);
    expect(find.text('Accomplir la quête'), findsOneWidget);

    final view = await container.read(questControllerProvider.future);
    expect(view?.quest.objectives, isNotEmpty);
    expect(view?.progress.every((done) => done == 0), isTrue);
    // La quête est enregistrée pour la journée.
    expect(await container.read(questRepositoryProvider).read(), view?.quest);
    await tester.unmountApp();
  });

  testWidgets('un jour de repos, le Système invite à récupérer', (
    tester,
  ) async {
    // testNow est un mercredi, jour de repos du profil de test.
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.systemHome);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.scrollUntilVisible(
      find.textContaining('Jour de repos'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(QuestPanel.startKey), findsNothing);
    await tester.unmountApp();
  });
}
