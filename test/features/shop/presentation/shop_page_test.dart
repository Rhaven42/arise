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
      200,
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

    expect(find.text("Boutique d'Arisia"), findsOneWidget);
    expect(find.textContaining('Ta bourse'), findsOneWidget);

    // Filtre « Dos » puis essayage de la cape.
    await tester.tap(find.text('Dos'));
    await tester.pump();
    expect(find.text('Cape du Vagabond'), findsOneWidget);
    expect(find.text('Veste de cuir de l\'Éveillé'), findsNothing);
    await tester.tap(find.text('Essayer').first);
    await tester.pump();
    expect(renderer.last?.itemNodes, ['item_cape_wanderer']);

    // Achat confirmé : 10 pièces d'argent.
    await tester.tap(find.text('Acheter').first);
    await tester.pumpAndSettle();
    expect(find.text('Confirmer l\'achat'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Acheter').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Achat réussi : Cape du Vagabond.'), findsOneWidget);
    final bag = await container.read(inventoryRepositoryProvider).read();
    expect(bag.owned, ['cape_wanderer']);
    expect(
      (await container.read(progressionRepositoryProvider).read())?.coins,
      250,
    );

    // Trop cher : la cape de l'Aube.
    await tester.tap(find.text('Acheter').first);
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
    await _scrollTo(tester, find.text('Équiper'), InventoryPage.listKey);
    await tester.tap(find.text('Équiper'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      (await container.read(inventoryRepositoryProvider).read()).equipped,
      {EquipmentSlot.back: 'cape_wanderer'},
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(renderer.last?.itemNodes, ['item_cape_wanderer']);

    await tester.tap(find.text('Teindre'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Forêt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Teinture appliquée.'), findsOneWidget);
    expect((await container.read(inventoryRepositoryProvider).read()).dyes, {
      'cape_wanderer': 0xFF3E6B34,
    });
    expect(
      (await container.read(progressionRepositoryProvider).read())?.coins,
      200,
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
    expect(find.text('Essayer'), findsNothing);
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
