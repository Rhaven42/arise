import 'package:arise/features/auth/data/firebase_auth_repository.dart';
import 'package:arise/features/auth/domain/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late _MockFirebaseAuth firebaseAuth;
  late FirebaseAuthRepository repository;

  setUp(() {
    firebaseAuth = _MockFirebaseAuth();
    repository = FirebaseAuthRepository(firebaseAuth);
  });

  test('convertit l’utilisateur Firebase en utilisateur du domaine', () {
    final user = _MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => user.displayName).thenReturn('Aria');
    when(
      firebaseAuth.authStateChanges,
    ).thenAnswer((_) => Stream.fromIterable([null, user]));

    expect(
      repository.authStateChanges(),
      emitsInOrder([null, const AuthUser(uid: 'u1', displayName: 'Aria')]),
    );
  });

  test('délègue la déconnexion à Firebase', () async {
    when(firebaseAuth.signOut).thenAnswer((_) async {});

    await repository.signOut();

    verify(firebaseAuth.signOut).called(1);
  });
}
