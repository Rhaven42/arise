import 'package:arise/features/character_creation/presentation/character_creator_page.dart';
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
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('01_taverne');

    await tapText(tester, "Commencer l'aventure");
    await tapText(tester, 'Force');
    await binding.takeScreenshot('02_objectif');
    await tapText(tester, 'Continuer');
    await tapText(tester, 'Débutant');
    await binding.takeScreenshot('03_niveau');
    await tapText(tester, 'Continuer');
    await tapText(tester, 'Haltères');
    await tapText(tester, 'Tapis');
    await binding.takeScreenshot('04_equipement');
    await tapText(tester, 'Continuer');
    await tapText(tester, 'Mercredi');
    await tapText(tester, 'Dimanche');
    await binding.takeScreenshot('05_repos');
    await tapText(tester, 'Continuer');
    await tapText(tester, "J'ai lu et compris ce rappel");
    await binding.takeScreenshot('06_sante');
    await tapText(tester, 'Entrer dans Arisia');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await binding.takeScreenshot('07_fenetre_du_systeme');

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('08_parametres');
    await tester.tap(find.text('Sauvegarde et données'));
    await tester.pumpAndSettle();
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
    await binding.takeScreenshot('10_exercices');
    await tester.enterText(find.byType(TextField), 'pompes');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pompes'));
    await pumpFor(1200);
    await binding.takeScreenshot('11_fiche_pompes');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    // Le champ doit reprendre le focus après le retour de la fiche pour que
    // la saisie soit prise en compte sur l'appareil.
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'squat');
    await tester.pumpAndSettle();
    if (find.text('Squat').evaluate().isEmpty) {
      // Aide au diagnostic : textes affichés si la recherche échoue.
      final texts = find
          .byType(Text)
          .evaluate()
          .map((element) => (element.widget as Text).data)
          .whereType<String>()
          .join(' | ');
      debugPrint('Textes visibles : $texts');
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Squat'));
    await tester.tap(find.text('Squat'));
    await pumpFor(1700);
    await binding.takeScreenshot('12_fiche_squat');
    await tester.binding.handlePopRoute();
    await pumpFor(800);
    await tester.tap(find.byTooltip('Créer un exercice'));
    await pumpFor(800);
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
    await binding.takeScreenshot('14_programme');
    await tapText(tester, 'Enregistrer');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tapText(tester, 'Planning');
    await tester.tap(find.byTooltip('Ajouter une séance le Lundi'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Rappel');
    await tapText(tester, 'Enregistrer');
    await binding.takeScreenshot('15_planning');

    // Phase 3 : lecteur de séance, intensité, repos et bilan.
    await tester.tap(find.byTooltip('Lancer Haut du corps'));
    await pumpFor(1500);
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
    await binding.takeScreenshot('17_intensite');
    await tester.tap(find.text('Valider'));
    await pumpFor(3200);
    await binding.takeScreenshot('18_repos');
    await tester.tap(find.byTooltip('Arrêter la séance'));
    await pumpFor(600);
    await tester.tap(find.text('Arrêter'));
    await pumpFor(2000);
    await binding.takeScreenshot('19_bilan');

    // Phase 4 : la Fenêtre du Système après la séance.
    await tester.tap(find.text('Retour'));
    await pumpFor(800);
    await tester.binding.handlePopRoute();
    await pumpFor(1200);
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
    await binding.takeScreenshot('21_analyse');
    await tester.scrollUntilVisible(
      find.text('Conseils du Système'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpFor(400);
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
    await binding.takeScreenshot('23_createur');
    await tester.tap(find.text('Humaine'));
    await pumpFor(800);
    await tester.tap(find.text('Orque').last);
    await pumpFor(800);
    await tester.tap(find.text('Femme'));
    await pumpFor(800);
    await tester.tap(find.text('Homme').last);
    await pumpFor(5000);
    await binding.takeScreenshot('24_createur_orque');
    await tester.tap(find.text('Orque').first);
    await pumpFor(800);
    await tester.tap(find.text('Elfe').last);
    await pumpFor(5000);
    await binding.takeScreenshot('25_createur_elfe');
    await tester.tap(find.text('Nom & fiche'));
    await pumpFor(1000);
    await tester.tap(find.text('Fiche du personnage (JSON)'));
    await pumpFor(800);
    await binding.takeScreenshot('26_createur_fiche');

    // Phase 6B : silhouettes, visage, coiffures, poses et éclairages.
    await tester.tap(find.text('Corps'));
    await pumpFor(1000);
    await tester.tap(find.text('Colosse'));
    await pumpFor(800);
    Future<void> pick(String menu, String choice) async {
      await tester.scrollUntilVisible(
        find.text(menu),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(CharacterCreatorPage.tabKey(CreatorTab.body)),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text(menu));
      await pumpFor(800);
      await tester.tap(find.text(choice).last);
      await pumpFor(800);
    }

    await pick('Détendue', 'Héroïque');
    await pumpFor(2500);
    await binding.takeScreenshot('27_createur_silhouette_pose');
    await tester.tap(find.text('Visage'));
    await pumpFor(800);
    await tester.tap(find.text('Aucune'));
    await pumpFor(800);
    await tester.tap(find.text('Collier').last);
    await pumpFor(2500);
    await binding.takeScreenshot('28_createur_visage');
    await tester.tap(find.text('Coiffure'));
    await pumpFor(1500);
    await tester.tap(find.text('Longues'));
    await pumpFor(800);
    await tester.tap(find.text('10 · Crinière'));
    await pumpFor(2500);
    await binding.takeScreenshot('29_createur_coiffures');
    await tester.tap(find.byTooltip('Éclairage'));
    await pumpFor(800);
    await tester.tap(find.text('Nuit'));
    await pumpFor(2500);
    await binding.takeScreenshot('30_createur_nuit');
  });
}
