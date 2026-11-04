import 'package:arise/core/router/app_routes.dart';

/// État du profil vu par le routeur.
enum ProfileStatus { unknown, missing, ready }

/// Calcule la redirection à appliquer avant d'afficher [location].
///
/// Renvoie `null` si aucun changement n'est nécessaire :
/// - sans profil, les écrans du jeu renvoient vers l'écran titre ;
/// - avec un profil, le questionnaire renvoie vers la Fenêtre du Système.
String? resolveRedirect({
  required String location,
  required ProfileStatus status,
}) {
  if (AppRoutes.requiresProfile(location) && status != ProfileStatus.ready) {
    return AppRoutes.title;
  }
  if (location == AppRoutes.onboarding && status == ProfileStatus.ready) {
    return AppRoutes.systemHome;
  }
  return null;
}
