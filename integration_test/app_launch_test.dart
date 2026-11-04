import 'package:arise/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

// Parcours réel sur appareil (émulateur Android en CI) : démarrage, base
// locale SQLite, questionnaire complet et arrivée dans la Fenêtre du Système.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('un nouveau joueur termine l’Éveil', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('ARISE'), findsOneWidget);
    await _tapText(tester, "Commencer l'aventure");

    await _tapText(tester, 'Endurance');
    await _tapText(tester, 'Continuer');
    await _tapText(tester, 'Intermédiaire');
    await _tapText(tester, 'Continuer');
    await _tapText(tester, 'Corde à sauter');
    await _tapText(tester, 'Continuer');
    await _tapText(tester, 'Samedi');
    await _tapText(tester, 'Continuer');
    await _tapText(tester, "J'ai lu et compris ce rappel");
    await _tapText(tester, 'Entrer dans Arisia');

    expect(find.text('Bienvenue, chasseur'), findsOneWidget);
    expect(find.text('Jours de repos : Samedi'), findsOneWidget);
  });
}
