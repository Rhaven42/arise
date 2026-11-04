import 'dart:math';

final _random = Random.secure();

/// Identifiant unique local (horodatage + aléa), par exemple `m3k9x2-a7f3q1`.
String generateId([DateTime? now]) {
  final time = (now ?? DateTime.now()).microsecondsSinceEpoch.toRadixString(36);
  final noise = _random.nextInt(1 << 31).toRadixString(36).padLeft(6, '0');
  return '$time-$noise';
}
