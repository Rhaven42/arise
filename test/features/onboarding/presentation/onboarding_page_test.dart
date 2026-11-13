import 'package:arise/features/character_creation/presentation/character_creator_page.dart';
import 'package:arise/features/onboarding/presentation/onboarding_controller.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

FilledButton _nextButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton));

void main() {
  testWidgets('le questionnaire complet crée le profil', (tester) async {
    final container = createTestContainer();
    await tester.pumpAriseApp(container);
    await _tapText(tester, "Commencer l'aventure");

    // Étape 1 : objectif.
    expect(find.text('Étape 1 sur 5'), findsOneWidget);
    expect(_nextButton(tester).onPressed, isNull);
    await _tapText(tester, 'Force');
    await _tapText(tester, 'Continuer');

    // Étape 2 : niveau.
    expect(find.text('Étape 2 sur 5'), findsOneWidget);
    await _tapText(tester, 'Débutant');
    await _tapText(tester, 'Continuer');

    // Étape 3 : équipement (facultatif).
    await _tapText(tester, 'Haltères');
    await _tapText(tester, 'Continuer');

    // Étape 4 : jours de repos.
    expect(_nextButton(tester).onPressed, isNull);
    await _tapText(tester, 'Mercredi');
    await _tapText(tester, 'Dimanche');
    expect(find.text('2 jours choisis'), findsOneWidget);
    await _tapText(tester, 'Continuer');

    // Étape 5 : santé et prudence.
    expect(_nextButton(tester).onPressed, isNull);
    await _tapText(tester, "J'ai lu et compris ce rappel");
    await _tapText(tester, 'Activer le Hero Protocol');

    // Le personnage se crée juste après le questionnaire.
    expect(find.byType(CharacterCreatorPage), findsOneWidget);
    expect(container.read(playerProfileProvider).value, sampleProfile);
    await tester.unmountApp();
  });

  testWidgets('pas plus de trois jours de repos', (tester) async {
    final container = createTestContainer();
    await tester.pumpAriseApp(container);
    await _tapText(tester, "Commencer l'aventure");
    await _tapText(tester, 'Endurance');
    await _tapText(tester, 'Continuer');
    await _tapText(tester, 'Avancé');
    await _tapText(tester, 'Continuer');
    await _tapText(tester, 'Continuer');

    for (final day in ['Lundi', 'Mardi', 'Mercredi', 'Jeudi']) {
      await _tapText(tester, day);
    }

    expect(find.text('3 jours choisis'), findsOneWidget);
    final draft = container.read(onboardingControllerProvider).value;
    expect(draft?.restDays, {1, 2, 3});
    await tester.unmountApp();
  });

  testWidgets('le bouton Retour revient à l’étape précédente', (tester) async {
    await tester.pumpAriseApp(createTestContainer());
    await _tapText(tester, "Commencer l'aventure");
    await _tapText(tester, 'Souplesse');
    await _tapText(tester, 'Continuer');

    await _tapText(tester, 'Retour');

    expect(find.text('Étape 1 sur 5'), findsOneWidget);
    await tester.unmountApp();
  });
}
