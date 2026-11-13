import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/health/presentation/health_page.dart';
import 'package:arise/features/health/presentation/health_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_health_source.dart';
import '../../../helpers/test_app.dart';

void main() {
  testWidgets('l écran Santé compte les verres et demande l accord', (
    tester,
  ) async {
    final source = FakeHealthSource();
    final container = createTestContainer(health: source);
    await tester.openWithProfile(container, AppRoutes.health);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(HealthPage), findsOneWidget);
    expect(find.text('Santé'), findsWidgets);
    // Sans accord, pas de lecture du téléphone ni de bouton de relecture.
    expect(source.authorizeCalls, 0);
    expect(find.byKey(HealthPage.syncKey), findsNothing);

    await tester.tap(find.byKey(HealthPage.addGlassKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('1 verre sur 8 (250 ml)'), findsOneWidget);

    await tester.tap(find.byKey(HealthPage.consentKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(HealthPage.syncKey), findsOneWidget);

    await tester.tap(find.byKey(HealthPage.syncKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(source.authorizeCalls, 1);
    expect(
      container.read(healthControllerProvider).value?.status,
      HealthSyncStatus.synced,
    );
    expect(find.text('Données du téléphone à jour.'), findsOneWidget);
    await tester.unmountApp();
  });
}
