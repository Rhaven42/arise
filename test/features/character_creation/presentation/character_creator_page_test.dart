import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/character_creation/presentation/character_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_character_renderer.dart';
import '../../../helpers/test_app.dart';

Future<void> _scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).last);

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

    final name = find.byType(TextField);
    await _scrollTo(tester, name);
    await tester.enterText(name, 'Al');
    await _scrollTo(tester, find.text('Valider le personnage'));
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
    await _scrollTo(tester, find.text('Valider le personnage'));
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
    await _scrollTo(tester, find.text('Valider le personnage'));
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
}
