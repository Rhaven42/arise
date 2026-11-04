import 'package:arise/core/router/app_router.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/router/route_guard.dart';
import 'package:arise/features/onboarding/presentation/title_page.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/progression/presentation/system_home_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  test('profileStatusFrom convertit chaque état', () {
    expect(profileStatusFrom(const AsyncLoading()), ProfileStatus.unknown);
    expect(profileStatusFrom(const AsyncData(null)), ProfileStatus.missing);
    expect(profileStatusFrom(AsyncData(sampleProfile)), ProfileStatus.ready);
    expect(
      profileStatusFrom(AsyncError(Exception('panne'), StackTrace.empty)),
      ProfileStatus.missing,
    );
  });

  testWidgets('sans profil, la Fenêtre du Système est inaccessible', (
    tester,
  ) async {
    final container = createTestContainer();
    await tester.pumpAriseApp(container);

    container.read(appRouterProvider).go(AppRoutes.systemHome);
    await tester.pumpAndSettle();

    expect(find.byType(SystemHomePage), findsNothing);
    expect(find.byType(TitlePage), findsOneWidget);
    await tester.unmountApp();
  });

  testWidgets('avec un profil, la Fenêtre du Système s’ouvre', (tester) async {
    final container = createTestContainer();
    await container.read(profileRepositoryProvider).saveProfile(sampleProfile);
    await tester.pumpAriseApp(container);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.byType(SystemHomePage), findsOneWidget);
    await tester.unmountApp();
  });
}
