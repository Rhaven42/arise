import 'package:arise/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';

String _describe(Failure failure) => switch (failure) {
  NetworkFailure() => 'network',
  UnauthenticatedFailure() => 'unauthenticated',
  PermissionDeniedFailure() => 'permission',
  NotFoundFailure() => 'notFound',
  StorageFailure() => 'storage',
  UnexpectedFailure() => 'unexpected',
};

void main() {
  test('les échecs sont des valeurs comparables', () {
    expect(
      const Failure.network(details: 'délai'),
      const Failure.network(details: 'délai'),
    );
    expect(
      const Failure.network(details: 'a'),
      isNot(const Failure.network(details: 'b')),
    );
  });

  test('le filtrage par motif est exhaustif', () {
    expect(_describe(const Failure.unauthenticated()), 'unauthenticated');
    expect(_describe(const Failure.storage()), 'storage');
  });
}
