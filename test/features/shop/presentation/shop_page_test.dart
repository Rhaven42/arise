import 'package:arise/core/router/app_router.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/character_creation/domain/character_rules.dart';
import 'package:arise/features/character_creation/presentation/character_providers.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/inventory/presentation/inventory_page.dart';
import 'package:arise/features/inventory/presentation/inventory_providers.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/features/shop/presentation/shop_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_character_renderer.dart';
import '../../../helpers/test_app.dart';

Future<void> _scrollTo(WidgetTester tester, Finder finder, Key list) =>
    tester.scrollUntilVisible(
      finder,
      600,
      scrollable: find
          .descendant(of: find.byKey(list), matching: find.byType(Scrollable))
          .first,
    );

void main() {
  testWidgets('essayer, acheter, équiper et teindre', (tester) async {
    final renderer = FakeCharacterRenderer();
    final container = createTestContainer(renderer: renderer);
    await container
        .read(progressionRepositoryProvider)
        .save(
          ProgressionState.initial(const CivilDate(2026, 11, 4))
              .copyWith(coins: 1250),
        );
    await container.read(characterRepositoryProvider).save(defaultSheet());
    await tester.openWithProfile(container, AppRoutes.shop);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Boutique du Protocole'), findsOneWidget);
    expect(find.textContaining('Ta bourse'), findsOneWidget);

    // Filtre « Tenue » puis essayage du cuir de l'Éveillé.
    final outfits = find.descendant(
      of: find.byKey(ShopPage.filtersKey),
      matching: find.text('Tenue'),
    );
    await tester.dragUntilVisible(
      outfits,
      find.byKey(ShopPage.filtersKey),
      const Offset(-150, 0),
    );
    await tester.tap(outfits);
    await tester.pump();
    expect(find.text("Cuir de l'Éveillé"), findsOneWidget);
    expect(find.text('Épée longue du Gardien'), findsNothing);
    // Grille de vignettes : un toucher ouvre la fiche de l'article.
    await tester.tap(find.text("Cuir de l'Éveillé"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir sur mon personnage'));
    await tester.pumpAndSettle();
    expect(find.text('Aperçu sur Création du personnage'), findsOneWidget);
    expect(renderer.last?.outfitId, 'awakened_leather');
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();

    // Achat confirmé depuis la fiche : 8 pièces d'argent.
    await tester.tap(find.widgetWithText(FilledButton, 'Acheter'));
    await tester.pumpAndSettle();
    expect(find.text("Confirmer l'achat"), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Acheter').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("Achat réussi : Cuir de l'Éveillé."), findsOneWidget);
    final bag = await container.read(inventoryRepositoryProvider).read();
    expect(bag.owned, ['awakened_leather']);
    expect(
      (await container.read(progressionRepositoryProvider).read())?.coins,
      450,
    );

    // Trop cher : la tenue suivante (la tenue achetée affiche « Possédé »).
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Possédé'), findsOneWidget);
    await tester.tap(
      find
          .descendant(
            of: find.byKey(ShopPage.listKey),
            matching: find.byType(InkWell),
          )
          .at(1),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Acheter'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Acheter').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text("Pas assez de pièces. Continue de t'entraîner !"),
      findsOneWidget,
    );

    // Inventaire : équiper puis teindre.
    container.read(appRouterProvider).go(AppRoutes.inventory);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Inventaire'), findsOneWidget);
    // Grille du sac : la fiche de l'objet pour le porter.
    await _scrollTo(
      tester,
      find.text("Cuir de l'Éveillé"),
      InventoryPage.listKey,
    );
    await tester.tap(find.text("Cuir de l'Éveillé"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Équiper'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      (await container.read(inventoryRepositoryProvider).read()).equipped,
      {EquipmentSlot.chest: 'awakened_leather'},
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(renderer.last?.outfitId, 'awakened_leather');

    await tester.tap(find.text("Cuir de l'Éveillé"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teindre'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Forêt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Teinture appliquée.'), findsOneWidget);
    expect((await container.read(inventoryRepositoryProvider).read()).dyes, {
      'awakened_leather': 0xFF3E6B34,
    });
    expect(
      (await container.read(progressionRepositoryProvider).read())?.coins,
      400,
    );
    await tester.unmountApp();
  });

  testWidgets('sans personnage, la boutique invite à le créer', (tester) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.shop);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Crée ton personnage pour essayer les objets.'),
      findsOneWidget,
    );
    expect(find.text('Voir sur mon personnage'), findsNothing);
    await _scrollTo(
      tester,
      find.text(
        "Tout s'achète avec les pièces gagnées en t'entraînant. Jamais "
        "d'argent réel.",
      ),
      ShopPage.listKey,
    );
    await tester.unmountApp();
  });
}
