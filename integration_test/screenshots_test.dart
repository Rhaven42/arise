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
    await tapText(tester, 'Squat');
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
  });
}
