import 'package:arise/core/router/app_router.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('le consentement santé se modifie depuis les paramètres', (
    tester,
  ) async {
    final container = createTestContainer();
    await container.read(profileRepositoryProvider).saveProfile(sampleProfile);
    await tester.pumpAriseApp(container);
    container.read(appRouterProvider).go(AppRoutes.settings);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    final profile = container.read(playerProfileProvider).value;
    expect(profile?.healthConsent, isTrue);
    await tester.unmountApp();
  });

  testWidgets('les bips et la voix du lecteur se règlent', (tester) async {
    final container = createTestContainer();
    await container.read(profileRepositoryProvider).saveProfile(sampleProfile);
    await tester.pumpAriseApp(container);
    container.read(appRouterProvider).go(AppRoutes.settings);
    await tester.pumpAndSettle();

    expect(find.text('Lecteur de séance'), findsOneWidget);
    await tester.tap(find.text('Bips et vibrations'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annonces vocales'));
    await tester.pumpAndSettle();

    final profile = container.read(playerProfileProvider).value;
    expect(profile?.workoutSounds, isFalse);
    expect(profile?.workoutVoice, isTrue);
    await tester.unmountApp();
  });

  testWidgets('le mode maladie se règle depuis les paramètres', (tester) async {
    final container = createTestContainer();
    await container.read(profileRepositoryProvider).saveProfile(sampleProfile);
    await tester.pumpAriseApp(container);
    container.read(appRouterProvider).go(AppRoutes.settings);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activer le mode maladie ou blessure'));
    await tester.pumpAndSettle();
    expect(find.text('Durée de la pause'), findsOneWidget);
    await tester.tap(find.text('Activer'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Actif jusqu'), findsOneWidget);
    final state = container.read(progressionControllerProvider).value?.state;
    expect(state?.sickUntil, isNotNull);

    await tester.tap(find.text("Reprendre l'entraînement"));
    await tester.pumpAndSettle();
    expect(find.text('Activer le mode maladie ou blessure'), findsOneWidget);
    await tester.unmountApp();
  });
}
