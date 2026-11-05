import 'package:arise/features/character_creation/domain/character_sheet.dart';

/// Teinte proposée dans un menu (identifiant stable + couleur ARGB).
class Swatch {
  const Swatch(this.id, this.color);

  final String id;
  final int color;
}

/// Teintes de peau naturelles (humains et elfes).
const List<Swatch> naturalSkins = [
  Swatch('porcelain', 0xFFF3D9C9),
  Swatch('ivory', 0xFFEBC6A8),
  Swatch('sand', 0xFFD9A982),
  Swatch('honey', 0xFFC48A5C),
  Swatch('amber', 0xFFA86E45),
  Swatch('cinnamon', 0xFF8A5434),
  Swatch('bronze', 0xFF6B3F27),
  Swatch('ebony', 0xFF45281A),
];

/// Teintes de peau des orques.
const List<Swatch> orcSkins = [
  Swatch('moss', 0xFF6E8B4A),
  Swatch('jade', 0xFF4F7A55),
  Swatch('olive', 0xFF7D7A45),
  Swatch('lichen', 0xFF8A9A6B),
  Swatch('slate', 0xFF5E6A6E),
  Swatch('ash', 0xFF7B7570),
];

/// Couleurs de cheveux.
const List<Swatch> hairColors = [
  Swatch('black', 0xFF1C1512),
  Swatch('dark_brown', 0xFF3B2416),
  Swatch('chestnut', 0xFF6A4026),
  Swatch('auburn', 0xFF7E2E17),
  Swatch('copper', 0xFFB4502A),
  Swatch('blond', 0xFFD8B26E),
  Swatch('ash_blond', 0xFFC2B49A),
  Swatch('grey', 0xFF8E8A86),
  Swatch('white', 0xFFE8E4DE),
  Swatch('midnight_blue', 0xFF1E2A4A),
];

/// Teintes de peau proposées pour une race.
List<Swatch> skinsFor(CharacterRace race) =>
    race == CharacterRace.orc ? orcSkins : naturalSkins;

/// Teinte d'une couleur dans une liste, ou `null` si elle n'y est pas.
Swatch? swatchOf(List<Swatch> swatches, int color) {
  for (final swatch in swatches) {
    if (swatch.color == color) return swatch;
  }
  return null;
}

/// Couleurs des yeux.
const List<Swatch> eyeColors = [
  Swatch('dark_brown', 0xFF3A2414),
  Swatch('brown', 0xFF5A3A22),
  Swatch('hazel', 0xFF7A6234),
  Swatch('green', 0xFF4C7A3E),
  Swatch('blue', 0xFF3E6A9A),
  Swatch('grey', 0xFF7C8690),
  Swatch('amber', 0xFFB07A26),
  Swatch('violet', 0xFF6A4C8C),
];
