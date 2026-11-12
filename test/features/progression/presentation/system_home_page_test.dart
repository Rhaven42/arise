import 'package:arise/core/design_system/widgets/stat_gem.dart';
import 'package:arise/core/router/app_router.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/inventory/presentation/inventory_page.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/features/quests/presentation/quests_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('un nouveau chasseur commence au niveau 0, rang E', (
    tester,
  ) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.systemHome);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Bienvenue, chasseur'), findsOneWidget);
    expect(find.text('Niveau 0'), findsOneWidget);
    expect(find.text('Rang E'), findsOneWidget);
    // Fiche du héros : pas encore de personnage ni de titre.
    expect(find.text('Sans titre'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == 'Bourse : 0 pièce de bronze',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Aucun jour en cours'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Boucliers : 0 sur 2'), findsOneWidget);

    final saved = await container.read(progressionRepositoryProvider).read();
    expect(saved?.level, 0);
    await tester.unmountApp();
  });

  testWidgets('les points libres se placent dans une stat', (tester) async {
    final container = createTestContainer();
    await container
        .read(progressionRepositoryProvider)
        .save(
          ProgressionState.initial(CivilDate.ofLocal(testNow))
              .copyWith(level: 1, freeStatPoints: 2),
        );
    await tester.openWithProfile(container, AppRoutes.systemHome);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('2 points à placer'), findsOneWidget);
    // Au-dessus de la barre d'action.
    await tester.ensureVisible(find.byTooltip('Ajouter un point à Force'));
    await tester.pump();
    await tester.tap(find.byTooltip('Ajouter un point à Force'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // La gemme de Force affiche la nouvelle valeur.
    expect(
      find.descendant(of: find.byType(StatGem).first, matching: find.text('1')),
      findsOneWidget,
    );
    expect(find.text('1 point à placer'), findsOneWidget);
    final saved = await container.read(progressionRepositoryProvider).read();
    expect(saved?.stat(StatId.strength), 1);
    await tester.unmountApp();
  });

  testWidgets('les jours manqués sont annoncés par le Système', (tester) async {
    final container = createTestContainer();
    // Dernière visite dimanche : lundi et mardi ont été manqués.
    await container
        .read(progressionRepositoryProvider)
        .save(
          ProgressionState.initial(const CivilDate(2026, 11, 1))
              .copyWith(streakDays: 4, bestStreak: 4),
        );
    await tester.openWithProfile(container, AppRoutes.systemHome);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Rapport du Système'), findsOneWidget);
    expect(
      find.text('2 jours manqués depuis ta dernière visite.'),
      findsOneWidget,
    );
    expect(find.textContaining('Ta série de 4 jours'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Zone de Pénalité'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Zone de Pénalité'), findsOneWidget);

    await tester.ensureVisible(find.text('Compris'));
    await tester.pump();
    await tester.tap(find.text('Compris'));
    await tester.pump();
    expect(find.text('Rapport du Système'), findsNothing);

    final saved = await container.read(progressionRepositoryProvider).read();
    expect(saved?.streakDays, 0);
    expect(saved?.bestStreak, 4);
    await tester.unmountApp();
  });

  testWidgets('la barre d’action ouvre les quêtes et l’inventaire', (
    tester,
  ) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.systemHome);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(HomeDock.questsKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(QuestsPage), findsOneWidget);

    container.read(appRouterProvider).go(AppRoutes.systemHome);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(HomeDock.bagKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(InventoryPage), findsOneWidget);
    await tester.unmountApp();
  });
}
