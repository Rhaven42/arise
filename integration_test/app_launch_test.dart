import 'package:arise/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

/// Avance le temps sans attendre la fin des animations en boucle.
Future<void> _pumpFor(WidgetTester tester, int milliseconds) async {
  for (var elapsed = 0; elapsed < milliseconds; elapsed += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

// Parcours réel sur appareil (émulateur Android en CI) : démarrage, base
// locale SQLite, questionnaire, catalogue d'exercices, programme et planning.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('un nouveau joueur termine l’Éveil puis planifie une séance', (
    tester,
  ) async {
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

    // Catalogue : recherche et fiche animée.
    await _tapText(tester, 'Exercices');
    await tester.enterText(find.byType(TextField), 'squat');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Squat'));
    await _pumpFor(tester, 1500);
    expect(find.text('Consignes'), findsOneWidget);
    await tester.pageBack();
    await _pumpFor(tester, 800);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Programme de Tabata.
    await _tapText(tester, 'Programmes');
    await _tapText(tester, 'Nouveau programme');
    await tester.enterText(find.byType(TextField), 'Tabata express');
    await _tapText(tester, 'Tabata, HIIT, circuit');
    await _tapText(tester, 'Ajouter un exercice');
    await tester.enterText(find.byType(TextField).last, 'burpees');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Burpees');
    expect(find.text('Durée estimée : 4 min'), findsOneWidget);
    await _tapText(tester, 'Enregistrer');
    expect(find.text('Tabata express'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Planning : séance le lundi, sans rappel (évite la demande
    // d'autorisation système pendant le test).
    await _tapText(tester, 'Planning');
    await tester.tap(find.byTooltip('Ajouter une séance le Lundi'));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Rappel');
    await _tapText(tester, 'Enregistrer');
    expect(find.text('Tabata express'), findsOneWidget);
  });
}
