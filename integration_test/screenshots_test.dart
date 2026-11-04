import 'package:arise/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Captures d'écran de référence, prises sur un émulateur Android
// (workflow « screenshots », lancé avec « flutter drive »).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tapText(WidgetTester tester, String text) async {
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
  });
}
