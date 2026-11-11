import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/quests/presentation/quests_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('la semaine, le donjon et sa première salle sont proposés', (
    tester,
  ) async {
    // Jeudi : jour d'entraînement du profil de test.
    final container = createTestContainer(
      clock: () => DateTime(2026, 11, 5, 10),
    );
    await tester.openWithProfile(container, AppRoutes.quests);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Quête de la semaine'), findsOneWidget);
    expect(find.text('Donjon de la semaine'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(QuestsPage.enterRoomKey(0)),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Entrer dans la salle 1'), findsOneWidget);
    await tester.unmountApp();
  });

  testWidgets('un jour de repos, aucune salle n’ouvre', (tester) async {
    // testNow est un mercredi, jour de repos du profil de test.
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.quests);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(QuestsPage.enterRoomKey(0)), findsNothing);
    await tester.unmountApp();
  });
}
