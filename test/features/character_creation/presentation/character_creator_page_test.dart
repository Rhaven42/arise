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
  double delta = 200,
}) => tester.scrollUntilVisible(
  finder,
  delta,
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
    // Dix races au choix.
    expect(find.text('Gobeline'), findsOneWidget);

    await tester.tap(find.text('Orque'));
    await tester.pumpAndSettle();
    expect(find.text('rendu:orc_female'), findsOneWidget);
    expect(renderer.last?.bodyId, 'orc_female');

    await tester.tap(find.text('Femme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Homme').last);
    await tester.pumpAndSettle();
    expect(find.text('rendu:orc_male'), findsOneWidget);
    expect(find.text('Minotaure'), findsOneWidget);

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
      find.text(
        "Ce nom n'est pas accepté dans Hero Protocol. Choisis-en un autre.",
      ),
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

  testWidgets('peau, coiffure, barbe et scène', (tester) async {
    // Écran de téléphone en hauteur : place pour l'aperçu et les réglages.
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final renderer = FakeCharacterRenderer();
    final sharer = FakeSnapshotSharer();
    final container = createTestContainer(renderer: renderer, sharer: sharer);
    await tester.openWithProfile(container, AppRoutes.character);
    await tester.pump(const Duration(milliseconds: 300));
    CharacterSheet sheet() =>
        container.read(characterCreatorControllerProvider).value!.sheet;

    // Teinte de peau : pastilles nommées.
    await _scrollTo(tester, find.byTooltip('Ébène'), tab: CreatorTab.body);
    await tester.ensureVisible(find.byTooltip('Ébène'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ébène'));
    await tester.pump();
    expect(sheet().skinColor, 0xFF45281A);
    expect(find.text('Couleur de peau : Ébène'), findsOneWidget);

    // L'onglet Coiffure cadre le visage ; pas de barbe pour une femme.
    await _openTab(tester, 'Coiffure');
    expect(renderer.lastScene?.focus, SceneFocus.face);
    expect(find.text('Barbe'), findsNothing);
    // Les coiffures de la boutique sont verrouillées.
    await _scrollTo(
      tester,
      find.text('10 · Mi-longue ondulée'),
      tab: CreatorTab.hair,
    );
    await tester.ensureVisible(find.text('10 · Mi-longue ondulée'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10 · Mi-longue ondulée'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(sheet().hairStyle, isNot(10));
    expect(find.text('Coiffure à débloquer dans la boutique.'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await _scrollTo(
      tester,
      find.text('3 · Deux tresses'),
      tab: CreatorTab.hair,
      delta: -200,
    );
    await tester.ensureVisible(find.text('3 · Deux tresses'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 · Deux tresses'));
    await tester.pump();
    expect(sheet().hairStyle, 3);
    expect(renderer.last?.hairId, 'f03');
    await _scrollTo(tester, find.byTooltip('Platine'), tab: CreatorTab.hair);
    await tester.ensureVisible(find.byTooltip('Platine'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Platine'));
    await tester.pump();
    expect(renderer.last?.hairColor, 0xFFEFE6CF);

    // Un homme a des barbes, de la couleur des cheveux par défaut.
    container
        .read(characterCreatorControllerProvider.notifier)
        .setSex(CharacterSex.male);
    await tester.pump();
    await _scrollTo(tester, find.text('Tressée'), tab: CreatorTab.hair);
    await tester.ensureVisible(find.text('Tressée'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tressée'));
    await tester.pump();
    expect(renderer.last?.beardId, 'b04');
    expect(renderer.last?.hairId, 'm03');
    expect(renderer.last?.beardColor, 0xFFEFE6CF);

    // Avant / après : l'aperçu montre la fiche d'ouverture.
    await tester.tap(find.byTooltip('Avant / après'));
    await tester.pump();
    expect(find.text('Aperçu : avant tes changements'), findsOneWidget);
    expect(renderer.last?.hairId, 'f01');
    await tester.tap(find.byTooltip('Avant / après'));
    await tester.pump();
    expect(renderer.last?.hairId, 'm03');

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
