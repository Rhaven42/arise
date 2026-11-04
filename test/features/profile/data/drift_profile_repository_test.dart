import 'dart:convert';

import 'package:arise/features/profile/data/drift_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  test('émet null, puis le profil enregistré, puis sa mise à jour', () async {
    final repository = DriftProfileRepository(createTestDatabase());
    final updated = sampleProfile.copyWith(healthConsent: true);

    final emissions = repository.watchProfile();
    final expectation = expectLater(
      emissions,
      emitsInOrder([isNull, sampleProfile, updated]),
    );

    await pumpEventQueue();
    await repository.saveProfile(sampleProfile);
    await pumpEventQueue();
    await repository.saveProfile(updated);
    await expectation;
  });

  test('décode un profil enregistré et ignore une absence', () {
    final json = jsonEncode(sampleProfile.toJson());
    expect(DriftProfileRepository.decodeProfile(json), sampleProfile);
    expect(DriftProfileRepository.decodeProfile(null), isNull);
  });
}
