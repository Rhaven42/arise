/// Chemins des écrans de l'application.
abstract final class AppRoutes {
  static const welcome = '/';
  static const designSystemSegment = 'design-system';
  static const designSystem = '/$designSystemSegment';
  static const systemHome = '/system';

  /// Écrans accessibles uniquement à un utilisateur connecté.
  static const protected = {systemHome};
}
