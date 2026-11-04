import 'package:arise/features/auth/domain/auth_user.dart';
import 'package:arise/features/auth/presentation/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_auth_repository.dart';

void main() {
  test('authState suit les connexions et déconnexions', () async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    final states = <AuthUser?>[];
    container.listen(
      authStateProvider,
      (_, next) {
        if (next case AsyncData(:final value)) states.add(value);
      },
      fireImmediately: true,
    );

    await Future<void>.delayed(Duration.zero);
    auth.emit(const AuthUser(uid: 'u1'));
    await Future<void>.delayed(Duration.zero);
    await auth.signOut();
    await Future<void>.delayed(Duration.zero);

    expect(states, [null, const AuthUser(uid: 'u1'), null]);
  });
}
