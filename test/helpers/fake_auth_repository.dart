import 'dart:async';

import 'package:arise/features/auth/domain/auth_repository.dart';
import 'package:arise/features/auth/domain/auth_user.dart';

/// Faux dépôt d'authentification piloté par les tests.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? initialUser}) : _current = initialUser;

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _current;

  /// Simule une connexion ou une déconnexion.
  void emit(AuthUser? user) {
    _current = user;
    _controller.add(user);
  }

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<void> signOut() async => emit(null);

  Future<void> dispose() => _controller.close();
}
