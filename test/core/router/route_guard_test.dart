import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/router/route_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveRedirect', () {
    test('laisse passer les écrans publics quel que soit l’état', () {
      for (final status in AuthStatus.values) {
        expect(
          resolveRedirect(location: AppRoutes.welcome, status: status),
          isNull,
        );
        expect(
          resolveRedirect(location: AppRoutes.designSystem, status: status),
          isNull,
        );
      }
    });

    test('renvoie vers l’accueil un visiteur non connecté', () {
      expect(
        resolveRedirect(
          location: AppRoutes.systemHome,
          status: AuthStatus.signedOut,
        ),
        AppRoutes.welcome,
      );
    });

    test('renvoie vers l’accueil tant que la session est inconnue', () {
      expect(
        resolveRedirect(
          location: AppRoutes.systemHome,
          status: AuthStatus.unknown,
        ),
        AppRoutes.welcome,
      );
    });

    test('laisse un utilisateur connecté accéder aux écrans protégés', () {
      expect(
        resolveRedirect(
          location: AppRoutes.systemHome,
          status: AuthStatus.signedIn,
        ),
        isNull,
      );
    });
  });
}
