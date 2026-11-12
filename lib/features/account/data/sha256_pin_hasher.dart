import 'dart:convert';
import 'dart:math';

import 'package:arise/features/account/domain/account_rules.dart';
import 'package:crypto/crypto.dart';

/// Empreinte SHA-256 salée, répétée pour ralentir les essais en série.
///
/// Le code PIN protège l'accès au compte depuis l'application ; les données
/// restent sur le téléphone.
class Sha256PinHasher implements PinHasher {
  Sha256PinHasher({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  static const _rounds = 10000;

  @override
  String newSalt() =>
      base64Url.encode(List<int>.generate(16, (_) => _random.nextInt(256)));

  @override
  String hash(String pin, String salt) {
    var digest = sha256.convert(utf8.encode('$salt:$pin')).bytes;
    for (var i = 0; i < _rounds; i++) {
      digest = sha256.convert([...digest, ...utf8.encode(salt)]).bytes;
    }
    return base64Url.encode(digest);
  }
}
