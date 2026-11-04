import 'dart:convert';
import 'dart:io';

import 'package:arise/core/config/game_config.dart';
import 'package:flutter_test/flutter_test.dart';

// Le même instantané est vérifié côté serveur (functions/test) : si les deux
// tests passent, les configurations client et serveur sont identiques.
void main() {
  test('la configuration correspond exactement à l’instantané partagé', () {
    final snapshot = jsonDecode(
      File('shared/game_config.snapshot.json').readAsStringSync(),
    );
    final exported = jsonDecode(jsonEncode(gameConfig.toJson()));

    expect(exported, equals(snapshot));
  });
}
