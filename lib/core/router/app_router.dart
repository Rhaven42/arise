import 'package:arise/core/design_system/demo/design_system_demo_page.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/router/route_guard.dart';
import 'package:arise/features/auth/domain/auth_user.dart';
import 'package:arise/features/auth/presentation/auth_providers.dart';
import 'package:arise/features/onboarding/presentation/welcome_page.dart';
import 'package:arise/features/progression/presentation/system_home_page.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Convertit l'état asynchrone d'authentification pour le routeur.
AuthStatus authStatusFrom(AsyncValue<AuthUser?> value) {
  return switch (value) {
    AsyncData(value: final user) =>
      user == null ? AuthStatus.signedOut : AuthStatus.signedIn,
    AsyncError() => AuthStatus.signedOut,
    _ => AuthStatus.unknown,
  };
}

/// Routeur de l'application, réévalué à chaque changement de session.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final status = ValueNotifier<AuthStatus>(AuthStatus.unknown);
  ref
    ..onDispose(status.dispose)
    ..listen<AsyncValue<AuthUser?>>(
      authStateProvider,
      (_, next) => status.value = authStatusFrom(next),
      fireImmediately: true,
    );

  final router = GoRouter(
    initialLocation: AppRoutes.welcome,
    refreshListenable: status,
    redirect: (_, state) => resolveRedirect(
      location: state.matchedLocation,
      status: status.value,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const WelcomePage(),
        routes: [
          GoRoute(
            path: AppRoutes.designSystemSegment,
            builder: (_, _) => const DesignSystemDemoPage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.systemHome,
        builder: (_, _) => const SystemHomePage(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
