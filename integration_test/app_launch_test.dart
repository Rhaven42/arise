import 'package:arise/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Attend qu'un widget apparaisse (au plus 10 s).
///
/// Les écritures dans la base locale se terminent hors du cycle d'images :
/// `pumpAndSettle` peut rendre la main avant la navigation qui suit.
Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var elapsed = 0; elapsed < 10000; elapsed += 100) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tapText(WidgetTester tester, String text) async {
  // Le clavier peut masquer le texte : on le ferme d'abord.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await _waitFor(tester, find.text(text));
  // Les listes ne construisent que les éléments visibles : on fait défiler
  // la page jusqu'au texte s'il n'est pas encore à l'écran.
  if (find.text(text).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

/// Revient en arrière jusqu'à l'écran qui affiche [text] (au plus 3 retours).
///
/// Un retour peut être absorbé par la fin d'une sauvegarde ou d'une
/// transition : on vérifie l'écran atteint au lieu de compter les retours.
Future<void> _backTo(WidgetTester tester, String text) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    await tester.pumpAndSettle();
    await _waitFor(tester, find.text(text));
    if (find.text(text).evaluate().isNotEmpty) return;
    await tester.binding.handlePopRoute();
  }
  await tester.pumpAndSettle();
}

/// Vérifie qu'un texte est affiché, en faisant défiler la page au besoin.
Future<void> _expectVisible(WidgetTester tester, String text) async {
  await _waitFor(tester, find.text(text));
  if (find.text(text).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  expect(find.text(text), findsOneWidget);
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
    await _waitFor(tester, find.text('Bienvenue, chasseur'));

    expect(find.text('Bienvenue, chasseur'), findsOneWidget);
    expect(find.text('Jours de repos : Samedi'), findsOneWidget);

    // Catalogue : recherche et fiche animée.
    await _tapText(tester, 'Exercices');
    await tester.enterText(find.byType(TextField), 'squat');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Squat'));
    await _pumpFor(tester, 1500);
    await tester.scrollUntilVisible(
      find.text('Consignes'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Consignes'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _pumpFor(tester, 800);
    await tester.binding.handlePopRoute();
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
    await _expectVisible(tester, 'Durée estimée : 4 min');
    await _tapText(tester, 'Enregistrer');
    expect(find.text('Tabata express'), findsOneWidget);
    await _backTo(tester, 'Planning');

    // Planning : séance le lundi, sans rappel (évite la demande
    // d'autorisation système pendant le test).
    await _tapText(tester, 'Planning');
    await tester.tap(find.byTooltip('Ajouter une séance le Lundi'));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Rappel');
    await _tapText(tester, 'Enregistrer');
    expect(find.text('Tabata express'), findsOneWidget);

    // Lecteur de séance lancé depuis le planning : un round, puis arrêt par
    // le bouton de prudence ; la séance interrompue est enregistrée.
    await _waitFor(tester, find.byTooltip('Lancer Tabata express'));
    await tester.tap(find.byTooltip('Lancer Tabata express'));
    await _pumpFor(tester, 1500);
    expect(find.textContaining('Round 1 sur 8'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Douleur ou malaise'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Douleur ou malaise'));
    await _waitFor(tester, find.text('Séance interrompue'));
    expect(find.text('Arrête-toi maintenant'), findsOneWidget);
    await _pumpFor(tester, 500);
  });
}
