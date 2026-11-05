import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/avatar/domain/character_scene.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:arise/features/character_creation/presentation/character_creator_page.dart';
import 'package:arise/features/character_creation/presentation/character_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_character_renderer.dart';
import '../../../helpers/test_app.dart';

Future<void> _scrollTo(
  WidgetTester tester,
  Finder finder, {
  CreatorTab tab = CreatorTab.sheet,
}) => tester.scrollUntilVisible(
  finder,
  200,
  scrollable: find
      .descendant(
        of: find.byKey(CharacterCreatorPage.tabKey(tab)),
        matching: find.byType(Scrollable),
      )
      .first,
);

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('les menus mettent à jour la fiche et le rendu', (tester) async {
    final renderer = FakeCharacterRenderer();
    final container = createTestContainer(renderer: renderer);
    await tester.openWithProfile(container, AppRoutes.character);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Création du personnage'), findsOneWidget);
    expect(find.text('rendu:human_female'), findsOneWidget);
    expect(find.text('Corpulence : Équilibrée'), findsOneWidget);

    await tester.tap(find.text('Humaine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orque').last);
    await tester.pumpAndSettle();
    expect(find.text('rendu:orc_female'), findsOneWidget);
    expect(renderer.last?.modelId, 'orc_female');

    await tester.tap(find.text('Femme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Homme').last);
    await tester.pumpAndSettle();
    expect(find.text('rendu:orc_male'), findsOneWidget);
    expect(find.text('Corpulence : Équilibré'), findsOneWidget);

    // Annuler revient à l'orque femme, puis à l'humaine.
    await tester.tap(find.byTooltip('Annuler'));
    await tester.pump();
    expect(find.text('rendu:orc_female'), findsOneWidget);
    await tester.tap(find.byTooltip('Annuler'));
    await tester.pump();
    expect(find.text('rendu:human_female'), findsOneWidget);
    await tester.tap(find.byTooltip('Rétablir'));
    await tester.pump();
    expect(find.text('rendu:orc_female'), findsOneWidget);

    // Le brouillon est conservé sur le téléphone.
    final draft = await container.read(characterRepositoryProvider).readDraft();
    expect(draft?.race.name, 'orc');
    await tester.unmountApp();
  });

  testWidgets('un nom refusé bloque la validation', (tester) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.character);
    await tester.pump(const Duration(milliseconds: 300));

    await _openTab(tester, 'Nom & fiche');
    final name = find.byType(TextField);
    await _scrollTo(tester, name);
    await tester.enterText(name, 'Al');
    await tester.tap(find.text('Valider le personnage'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await _scrollTo(tester, name);
    expect(
      find.text('Le nom doit faire au moins 3 caractères.'),
      findsOneWidget,
    );
    expect(await container.read(characterRepositoryProvider).read(), isNull);

    await tester.enterText(name, 'Connard');
    await tester.tap(find.text('Valider le personnage'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await _scrollTo(tester, name);
    expect(
      find.text("Ce nom n'est pas accepté dans Arisia. Choisis-en un autre."),
      findsOneWidget,
    );
    await tester.unmountApp();
  });

  testWidgets('aléatoire, fiche JSON et validation', (tester) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.character);
    await tester.pump(const Duration(milliseconds: 300));

    await _openTab(tester, 'Nom & fiche');
    await _scrollTo(tester, find.text('Aléatoire'));
    await tester.tap(find.text('Aléatoire'));
    await tester.pump();
    final random = container
        .read(characterCreatorControllerProvider)
        .value
        ?.sheet;
    expect(random, isNotNull);

    await _scrollTo(tester, find.text('Fiche du personnage (JSON)'));
    await tester.tap(find.text('Fiche du personnage (JSON)'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('"race": "${random!.race.name}"'),
      findsOneWidget,
    );

    final name = find.byType(TextField);
    await _scrollTo(tester, name);
    await tester.enterText(name, 'Aelin');
    await tester.tap(find.text('Valider le personnage'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final saved = await container.read(characterRepositoryProvider).read();
    expect(saved?.name, 'Aelin');
    expect(saved?.race, random.race);
    expect(
      await container.read(characterRepositoryProvider).readDraft(),
      isNull,
    );
    expect(find.text('Personnage enregistré.'), findsOneWidget);
    await tester.unmountApp();
  });

  testWidgets('silhouettes, visage, coiffures favorites et scène', (
    tester,
  ) async {
    final renderer = FakeCharacterRenderer();
    final sharer = FakeSnapshotSharer();
    final container = createTestContainer(renderer: renderer, sharer: sharer);
    await tester.openWithProfile(container, AppRoutes.character);
    await tester.pump(const Duration(milliseconds: 300));
    CharacterSheet sheet() =>
        container.read(characterCreatorControllerProvider).value!.sheet;

    // Silhouette « Nageuse ».
    await _scrollTo(tester, find.text('Nageuse'), tab: CreatorTab.body);
    await tester.tap(find.text('Nageuse'));
    await tester.pump();
    expect(sheet().corpulence, 0.25);
    expect(sheet().musculature, 0.75);

    // L'onglet Visage cadre la caméra sur le visage.
    await _openTab(tester, 'Visage');
    expect(renderer.lastScene?.focus, SceneFocus.face);
    expect(find.text('Mâchoire : Moyenne'), findsOneWidget);
    // Pas de barbe pour un personnage féminin.
    expect(find.text('Barbe'), findsNothing);
    await _scrollTo(tester, find.text('Aucun'), tab: CreatorTab.face);
    await tester.tap(find.text('Aucun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khôl').last);
    await tester.pumpAndSettle();
    expect(sheet().makeupStyle, 1);
    expect(renderer.last?.makeupId, 'makeup_01');

    // Coiffures : favorites jusqu'à la limite.
    await _openTab(tester, 'Coiffure');
    expect(renderer.lastScene?.focus, SceneFocus.body);
    await tester.tap(find.text('Favorites'));
    await tester.pump();
    expect(
      find.text(
        "Aucune favorite : touche l'étoile d'une coiffure pour la garder "
        'sous la main.',
      ),
      findsOneWidget,
    );
    final controller = container.read(
      characterCreatorControllerProvider.notifier,
    );
    final max = gameConfig.character.favoriteHairstylesMax;
    for (var i = 1; i <= max; i++) {
      controller.toggleFavorite(i);
    }
    await tester.pump();
    expect(sheet().favoriteHairStyles, hasLength(max));
    await tester.tap(find.text('Longues'));
    await tester.pump();
    await tester.tap(find.byTooltip('Ajouter aux favorites').first);
    await tester.pump();
    expect(
      find.text('Tu as déjà $max coiffures favorites. Retires-en une '
          "d'abord."),
      findsOneWidget,
    );
    await tester.tap(find.text('10 · Crinière'));
    await tester.pump();
    expect(sheet().hairStyle, 10);

    // Avant / après : l'aperçu montre la fiche d'ouverture.
    await tester.tap(find.byTooltip('Avant / après'));
    await tester.pump();
    expect(find.text('Aperçu : avant tes changements'), findsOneWidget);
    expect(renderer.last?.hairStyleId, 'hair_01');
    await tester.tap(find.byTooltip('Avant / après'));
    await tester.pump();
    expect(renderer.last?.hairStyleId, 'hair_10');

    // Éclairage de nuit.
    await tester.tap(find.byTooltip('Éclairage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuit'));
    await tester.pumpAndSettle();
    expect(renderer.lastScene?.lighting, SceneLighting.night);

    // Partage d'une capture.
    await tester.tap(find.byTooltip('Partager une capture'));
    await tester.pump();
    expect(sharer.shared, hasLength(1));
    expect(sharer.shared.single.png, FakeCharacterRenderer.png);
    expect(sharer.shared.single.fileName, 'arise_heros.png');
    await tester.unmountApp();
  });
}
