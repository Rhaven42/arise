import 'package:arise/core/router/app_router.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
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

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final profile = await container
        .read(profileRepositoryProvider)
        .watchProfile()
        .first;
    expect(profile?.healthConsent, isTrue);
    await tester.unmountApp();
  });
}
