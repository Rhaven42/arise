import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/router/route_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveRedirect', () {
    test('laisse toujours passer l’écran titre et la restauration', () {
      for (final status in ProfileStatus.values) {
        for (final location in [
          AppRoutes.title,
          AppRoutes.designSystem,
          AppRoutes.restore,
        ]) {
          expect(resolveRedirect(location: location, status: status), isNull);
        }
      }
    });

    test('renvoie vers l’écran titre tant qu’il n’y a pas de profil', () {
      for (final status in [ProfileStatus.unknown, ProfileStatus.missing]) {
        for (final location in [
          AppRoutes.systemHome,
          AppRoutes.settings,
          AppRoutes.backup,
        ]) {
          expect(
            resolveRedirect(location: location, status: status),
            AppRoutes.title,
          );
        }
      }
    });

    test('ouvre les écrans du jeu une fois le profil créé', () {
      expect(
        resolveRedirect(
          location: AppRoutes.settings,
          status: ProfileStatus.ready,
        ),
        isNull,
      );
    });

    test('ne repropose pas le questionnaire à un joueur déjà éveillé', () {
      expect(
        resolveRedirect(
          location: AppRoutes.onboarding,
          status: ProfileStatus.ready,
        ),
        AppRoutes.systemHome,
      );
      expect(
        resolveRedirect(
          location: AppRoutes.onboarding,
          status: ProfileStatus.missing,
        ),
        isNull,
      );
    });
  });
}
