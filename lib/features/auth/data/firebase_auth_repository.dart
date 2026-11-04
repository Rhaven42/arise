import 'package:arise/features/auth/domain/auth_repository.dart';
import 'package:arise/features/auth/domain/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Implémentation Firebase Auth de [AuthRepository].
class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<AuthUser?> authStateChanges() {
    return _auth.authStateChanges().map(
      (user) => user == null
          ? null
          : AuthUser(uid: user.uid, displayName: user.displayName),
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
