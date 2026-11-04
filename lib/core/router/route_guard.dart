import 'package:arise/core/router/app_routes.dart';

/// État d'authentification vu par le routeur.
enum AuthStatus { unknown, signedIn, signedOut }

/// Calcule la redirection à appliquer avant d'afficher [location].
///
/// Renvoie `null` si aucun changement n'est nécessaire. Tant que l'état est
/// inconnu ou déconnecté, les écrans protégés renvoient vers l'accueil.
String? resolveRedirect({
  required String location,
  required AuthStatus status,
}) {
  final isProtected = AppRoutes.protected.contains(location);
  if (isProtected && status != AuthStatus.signedIn) {
    return AppRoutes.welcome;
  }
  return null;
}
