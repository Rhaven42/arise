import 'package:arise/app.dart';
import 'package:arise/core/router/app_router.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/router/route_guard.dart';
import 'package:arise/features/auth/domain/auth_user.dart';
import 'package:arise/features/auth/presentation/auth_providers.dart';
import 'package:arise/features/onboarding/presentation/welcome_page.dart';
import 'package:arise/features/progression/presentation/system_home_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  group('authStatusFrom', () {
    test('convertit chaque état asynchrone', () {
      expect(authStatusFrom(const AsyncLoading()), AuthStatus.unknown);
      expect(authStatusFrom(const AsyncData(null)), AuthStatus.signedOut);
      expect(
        authStatusFrom(const AsyncData(AuthUser(uid: 'u1'))),
        AuthStatus.signedIn,
      );
      expect(
        authStatusFrom(AsyncError(Exception('panne'), StackTrace.empty)),
        AuthStatus.signedOut,
      );
    });
  });

  group('appRouter', () {
    late FakeAuthRepository auth;

    setUp(() => auth = FakeAuthRepository());
    tearDown(() => auth.dispose());

    Future<ProviderContainer> pumpRouterApp(WidgetTester tester) async {
      final container = ProviderContainer.test(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AriseApp(),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('démarre sur l’accueil', (tester) async {
      await pumpRouterApp(tester);
      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('refuse la Fenêtre du Système sans connexion', (tester) async {
      final container = await pumpRouterApp(tester);

      container.read(appRouterProvider).go(AppRoutes.systemHome);
      await tester.pumpAndSettle();

      expect(find.byType(SystemHomePage), findsNothing);
      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('ouvre la Fenêtre du Système une fois connecté', (
      tester,
    ) async {
      final container = await pumpRouterApp(tester);

      auth.emit(const AuthUser(uid: 'u1'));
      await tester.pumpAndSettle();
      container.read(appRouterProvider).go(AppRoutes.systemHome);
      await tester.pumpAndSettle();

      expect(find.byType(SystemHomePage), findsOneWidget);
    });
  });
}
