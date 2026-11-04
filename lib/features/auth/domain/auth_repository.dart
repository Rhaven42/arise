import 'package:arise/features/auth/domain/auth_user.dart';

/// Accès à l'état d'authentification.
abstract interface class AuthRepository {
  /// Émet l'utilisateur connecté, ou `null` lorsqu'il est déconnecté.
  Stream<AuthUser?> authStateChanges();

  /// Ferme la session en cours.
  Future<void> signOut();
}
