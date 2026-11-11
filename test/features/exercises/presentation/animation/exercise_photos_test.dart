import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  test('chaque photo appartient à un exercice du catalogue', () {
    final ids = {for (final e in testCatalog) e.id};
    expect(testPhotoIds, isNotEmpty);
    for (final id in testPhotoIds) {
      expect(ids, contains(id));
    }
  });

  test('les photos importées suivent la table de correspondance', () {
    final mapping = jsonDecode(
      File('tool/exercise_photos/mapping.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final photos = (mapping['photos'] as Map<String, dynamic>).keys.toSet();
    expect(testPhotoIds, photos);
    for (final id in photos) {
      expect(File('assets/exercise_photos/${id}_1.webp').existsSync(), isTrue);
    }
  });
}
