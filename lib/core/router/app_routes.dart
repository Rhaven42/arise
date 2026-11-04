/// Chemins des écrans de l'application.
abstract final class AppRoutes {
  static const title = '/';
  static const designSystemSegment = 'design-system';
  static const String designSystem = '/$designSystemSegment';
  static const onboarding = '/onboarding';
  static const restore = '/restore';
  static const systemHome = '/system';
  static const settingsSegment = 'settings';
  static const String settings = '$systemHome/$settingsSegment';
  static const backupSegment = 'backup';
  static const String backup = '$settings/$backupSegment';

  /// Vrai pour les écrans réservés à un joueur ayant terminé l'Éveil.
  static bool requiresProfile(String location) =>
      location == systemHome || location.startsWith('$systemHome/');
}
