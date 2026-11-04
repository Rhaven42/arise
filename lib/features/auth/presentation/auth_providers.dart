import 'package:arise/features/auth/data/firebase_auth_repository.dart';
import 'package:arise/features/auth/domain/auth_repository.dart';
import 'package:arise/features/auth/domain/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return FirebaseAuthRepository(FirebaseAuth.instance);
}

/// Utilisateur connecté (ou `null`), mis à jour en continu.
@Riverpod(keepAlive: true)
Stream<AuthUser?> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}
