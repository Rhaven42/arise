import 'package:arise/core/router/app_router.dart';
import 'package:arise/features/account/presentation/account_create_page.dart';
import 'package:arise/features/character_creation/presentation/character_creator_page.dart';
import 'package:arise/features/shop/presentation/shop_page.dart';
import 'package:arise/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Captures d'écran de référence, prises sur un émulateur Android
// (workflow « screenshots », lancé avec « flutter drive »).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tapText(WidgetTester tester, String text) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    if (find.text(text).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('captures du parcours d’arrivée', (tester) async {
    // L'émulateur de la CI rend tout en logiciel : les démonstrations
    // vidéo y tournent en image fixe (mode « animations réduites »).
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    debugPrint('capture 01_taverne');
    await binding.takeScreenshot('01_taverne');

    await tapText(tester, "Commencer l'aventure");
    await tester.enterText(find.byKey(AccountCreatePage.nameKey), 'Aelin');
    await tester.pumpAndSettle();
    debugPrint('capture 01b_compte');
    await binding.takeScreenshot('01b_compte');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AccountCreatePage.createKey));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tapText(tester, 'Force');
    debugPrint('capture 02_objectif');
    await binding.takeScreenshot('02_objectif');
    await tapText(tester, 'Continuer');
    await tapText(tester, 'Débutant');
    debugPrint('capture 03_niveau');
    await binding.takeScreenshot('03_niveau');
    await tapText(tester, 'Continuer');
    await tapText(tester, 'Haltères');
    await tapText(tester, 'Tapis');
    debugPrint('capture 04_equipement');
    await binding.takeScreenshot('04_equipement');
    await tapText(tester, 'Continuer');
    await tapText(tester, 'Mercredi');
    await tapText(tester, 'Dimanche');
    debugPrint('capture 05_repos');
    await binding.takeScreenshot('05_repos');
    await tapText(tester, 'Continuer');
    await tapText(tester, "J'ai lu et compris ce rappel");
    debugPrint('capture 06_sante');
    await binding.takeScreenshot('06_sante');
    await tapText(tester, 'Entrer dans Arisia');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    debugPrint('capture 07_fenetre_du_systeme');
    await binding.takeScreenshot('07_fenetre_du_systeme');

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    debugPrint('capture 08_parametres');
    await binding.takeScreenshot('08_parametres');
    await tester.tap(find.text('Sauvegarde et données'));
    await tester.pumpAndSettle();
    debugPrint('capture 09_sauvegarde');
    await binding.takeScreenshot('09_sauvegarde');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    Future<void> pumpFor(int milliseconds) async {
      for (var t = 0; t < milliseconds; t += 100) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    // Phase 2 : exercices, fiche animée, exercice perso, programme, planning.
    await tapText(tester, 'Exercices');
    debugPrint('capture 10_exercices');
    await binding.takeScreenshot('10_exercices');
    await tester.enterText(find.byType(TextField), 'pompes');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pompes'));
    await pumpFor(1200);
    debugPrint('capture 11_fiche_pompes');
    await binding.takeScreenshot('11_fiche_pompes');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    // Retour à la Fenêtre du Système puis nouvelle ouverture du catalogue :
    // sur l'émulateur, une seconde saisie dans le même champ, après le retour
    // de la fiche, n'était pas toujours prise en compte.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tapText(tester, 'Exercices');
    await tester.enterText(find.byType(TextField).first, 'squat');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Squat'));
    await tester.tap(find.text('Squat'));
    await pumpFor(1700);
    debugPrint('capture 12_fiche_squat');
    await binding.takeScreenshot('12_fiche_squat');
    await tester.binding.handlePopRoute();
    await pumpFor(800);
    await tester.tap(find.byTooltip('Créer un exercice'));
    await pumpFor(800);
    debugPrint('capture 13_exercice_perso');
    await binding.takeScreenshot('13_exercice_perso');
    await tester.binding.handlePopRoute();
    await pumpFor(800);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tapText(tester, 'Programmes');
    await tapText(tester, 'Nouveau programme');
    await tester.enterText(find.byType(TextField), 'Haut du corps');
    await tapText(tester, 'Ajouter un exercice');
    await tester.enterText(find.byType(TextField).last, 'pompes');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pompes').last);
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    debugPrint('capture 14_programme');
    await binding.takeScreenshot('14_programme');
    await tapText(tester, 'Enregistrer');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tapText(tester, 'Planning');
    await tester.tap(find.byTooltip('Ajouter une séance le Lundi'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Rappel');
    await tapText(tester, 'Enregistrer');
    debugPrint('capture 15_planning');
    await binding.takeScreenshot('15_planning');

    // Phase 3 : lecteur de séance, intensité, repos et bilan.
    await tester.tap(find.byTooltip('Lancer Haut du corps'));
    await pumpFor(1500);
    debugPrint('capture 16_lecteur_serie');
    await binding.takeScreenshot('16_lecteur_serie');
    await tester.scrollUntilVisible(
      find.text('Série terminée'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Série terminée'));
    await pumpFor(600);
    await tester.tap(find.text('7'));
    await pumpFor(300);
    debugPrint('capture 17_intensite');
    await binding.takeScreenshot('17_intensite');
    await tester.tap(find.text('Valider'));
    await pumpFor(3200);
    debugPrint('capture 18_repos');
    await binding.takeScreenshot('18_repos');
    await tester.tap(find.byTooltip('Arrêter la séance'));
    await pumpFor(600);
    await tester.tap(find.text('Arrêter'));
    await pumpFor(2000);
    debugPrint('capture 19_bilan');
    await binding.takeScreenshot('19_bilan');

    // Phase 4 : la Fenêtre du Système après la séance (le bouton est sous
    // les hauts faits obtenus).
    await tester.scrollUntilVisible(
      find.text('Retour'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Retour'));
    await pumpFor(800);
    await tester.binding.handlePopRoute();
    await pumpFor(1200);
    debugPrint('capture 20_fenetre_apres_seance');
    await binding.takeScreenshot('20_fenetre_apres_seance');

    // Phase 5 : l'analyse musculaire.
    final analysis = find.text('Analyse musculaire');
    await tester.scrollUntilVisible(
      analysis,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(analysis.last);
    await pumpFor(1500);
    debugPrint('capture 21_analyse');
    await binding.takeScreenshot('21_analyse');
    await tester.scrollUntilVisible(
      find.text('Conseils du Système'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpFor(400);
    debugPrint('capture 22_analyse_conseils');
    await binding.takeScreenshot('22_analyse_conseils');

    // Phase 6 : le créateur de personnage (rendu 3D réel).
    await tester.binding.handlePopRoute();
    await pumpFor(1200);
    final creator = find.text('Création du personnage');
    await tester.scrollUntilVisible(
      creator,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(creator.last);
    await pumpFor(6000);
    debugPrint('capture 23_createur');
    await binding.takeScreenshot('23_createur');
    await tester.tap(find.text('Humaine'));
    await pumpFor(800);
    await tester.tap(find.text('Orque').last);
    await pumpFor(800);
    await tester.tap(find.text('Femme'));
    await pumpFor(800);
    await tester.tap(find.text('Homme').last);
    await pumpFor(5000);
    debugPrint('capture 24_createur_orque');
    await binding.takeScreenshot('24_createur_orque');
    await tester.tap(find.text('Orque').first);
    await pumpFor(800);
    await tester.tap(find.text('Elfe').last);
    await pumpFor(5000);
    debugPrint('capture 25_createur_elfe');
    await binding.takeScreenshot('25_createur_elfe');
    await tester.tap(find.text('Nom & fiche'));
    await pumpFor(1000);
    await tester.tap(find.text('Fiche du personnage (JSON)'));
    await pumpFor(800);
    debugPrint('capture 26_createur_fiche');
    await binding.takeScreenshot('26_createur_fiche');

    // Phase 6B : silhouettes, visage, coiffures, poses et éclairages.
    await tester.tap(find.text('Corps'));
    await pumpFor(1000);
    await tester.tap(find.text('Colosse'));
    await pumpFor(800);
    Future<void> pick(
      String menu,
      String choice, {
      CreatorTab tab = CreatorTab.body,
    }) async {
      final list = find
          .descendant(
            of: find.byKey(CharacterCreatorPage.tabKey(tab)),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(find.text(menu), 200, scrollable: list);
      // Remonte le menu au milieu de la liste pour le toucher sans gêne.
      await tester.drag(list, const Offset(0, -150));
      await pumpFor(600);
      await tester.tap(find.text(menu));
      await pumpFor(800);
      await tester.tap(find.text(choice).last);
      await pumpFor(800);
    }

    await pumpFor(2500);
    debugPrint('capture 27_createur_silhouette');
    await binding.takeScreenshot('27_createur_silhouette');
    await tester.tap(find.text('Visage'));
    await pumpFor(800);
    await pick('Aucune', 'Collier', tab: CreatorTab.face);
    await pumpFor(2500);
    debugPrint('capture 28_createur_visage');
    await binding.takeScreenshot('28_createur_visage');
    await tester.tap(find.text('Coiffure'));
    await pumpFor(1500);
    await tester.tap(find.text('Longues'));
    await pumpFor(800);
    await tester.tap(find.text('5 · Longue'));
    await pumpFor(2500);
    debugPrint('capture 29_createur_coiffures');
    await binding.takeScreenshot('29_createur_coiffures');
    await tester.tap(find.byTooltip('Éclairage'));
    await pumpFor(800);
    await tester.tap(find.text('Nuit'));
    await pumpFor(2500);
    debugPrint('capture 30_createur_nuit');
    await binding.takeScreenshot('30_createur_nuit');

    // Phase 7 : boutique (essayages) et inventaire.
    await tester.tap(find.text('Nom & fiche'));
    await pumpFor(800);
    await tester.enterText(find.byType(TextField), 'Thalion');
    await pumpFor(500);
    FocusManager.instance.primaryFocus?.unfocus();
    await pumpFor(500);
    await tester.tap(find.text('Valider le personnage'));
    await pumpFor(2500);
    final shop = find.text("Boutique d'Arisia");
    await tester.scrollUntilVisible(
      shop,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(shop);
    await pumpFor(5000);
    debugPrint('capture 31_boutique');
    await binding.takeScreenshot('31_boutique');
    Future<void> tryOn(String filter, int index, String shot) async {
      await tester.dragUntilVisible(
        find.text(filter),
        find.byKey(ShopPage.filtersKey),
        const Offset(-150, 0),
      );
      await pumpFor(300);
      await tester.tap(find.text(filter));
      await pumpFor(600);
      final button = find.text('Voir sur mon personnage').at(index);
      await tester.ensureVisible(button);
      await pumpFor(300);
      await tester.tap(button);
      // Le premier rendu d'un modèle dans une nouvelle vue web est très lent
      // sur l'émulateur (rendu logiciel, sans carte graphique : shaders et
      // textures préparés par le processeur) : on attend qu'il soit dessiné.
      for (var t = 0; t < 60000; t += 500) {
        if (find.text('Le Système façonne ton héros…').evaluate().isEmpty) {
          break;
        }
        await pumpFor(500);
      }
      await pumpFor(1500);
      await binding.takeScreenshot(shot);
      await tester.tap(find.byTooltip('Fermer'));
      await pumpFor(800);
    }

    await tryOn('Torse', 2, '32_boutique_cuirasse');
    await tryOn('Dos', 1, '33_boutique_cape');
    await tryOn('Arme', 0, '34_boutique_epee');

    // Phase 8A : quête du jour et épreuve de rang.
    await tester.binding.handlePopRoute();
    await pumpFor(1200);
    await tester.scrollUntilVisible(
      find.text('Quête du jour'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpFor(800);
    debugPrint('capture 35_quete_du_jour');
    await binding.takeScreenshot('35_quete_du_jour');
    await tester.scrollUntilVisible(
      find.text("Voir l'épreuve"),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text("Voir l'épreuve"));
    await pumpFor(1500);
    debugPrint('capture 36_epreuve_de_rang');
    await binding.takeScreenshot('36_epreuve_de_rang');

    // Inventaire, depuis la barre d'action.
    await tester.binding.handlePopRoute();
    await pumpFor(1200);
    await tester.tap(find.byKey(HomeDock.inventoryKey));
    await pumpFor(1200);
    debugPrint('capture 37_inventaire');
    await binding.takeScreenshot('37_inventaire');
  });
}
