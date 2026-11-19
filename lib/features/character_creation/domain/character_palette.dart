import 'package:arise/features/character_creation/domain/character_sheet.dart';

/// Teinte proposée dans un menu (identifiant stable + couleur ARGB).
class Swatch {
  const Swatch(this.id, this.color);

  final String id;
  final int color;
}

/// Teintes de peau naturelles (humains, elfes, nains, gnomes).
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

/// Teintes de peau des hauts-elfes (dorées et pâles).
const List<Swatch> highElfSkins = [
  Swatch('golden', 0xFFF0CF8E),
  Swatch('porcelain', 0xFFF3D9C9),
  Swatch('ivory', 0xFFEBC6A8),
  Swatch('moon', 0xFFD9DCE8),
  Swatch('honey', 0xFFC48A5C),
  Swatch('bronze', 0xFF6B3F27),
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

/// Teintes de peau des gobelins.
const List<Swatch> goblinSkins = [
  Swatch('lime', 0xFF8DB43C),
  Swatch('moss', 0xFF6E8B4A),
  Swatch('jade', 0xFF4F7A55),
  Swatch('swamp', 0xFF5F6B32),
  Swatch('teal', 0xFF3F7F74),
  Swatch('ash', 0xFF7B7570),
];

/// Teintes de peau des démons.
const List<Swatch> demonSkins = [
  Swatch('crimson', 0xFFB0282A),
  Swatch('scarlet', 0xFFD24A2E),
  Swatch('wine', 0xFF7A1E3A),
  Swatch('violet', 0xFF6A3A9A),
  Swatch('azure', 0xFF3A6AB0),
  Swatch('obsidian', 0xFF3A3440),
];

/// Pelages des minotaures.
const List<Swatch> minotaurSkins = [
  Swatch('chestnut', 0xFF7A4E2E),
  Swatch('tawny', 0xFFB07A44),
  Swatch('umber', 0xFF4A3222),
  Swatch('black', 0xFF2E2622),
  Swatch('cream', 0xFFD8C4A2),
  Swatch('grey', 0xFF8A8480),
];

/// Teintes des morts-vivants.
const List<Swatch> undeadSkins = [
  Swatch('ash', 0xFFA8ACA0),
  Swatch('bone', 0xFFD0CCC0),
  Swatch('grave', 0xFF8A9A88),
  Swatch('frost', 0xFF9AAFC0),
  Swatch('dusk', 0xFF8A7F96),
  Swatch('slate', 0xFF5E6A6E),
];

/// Couleurs de cheveux et de barbe.
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
  Swatch('platinum', 0xFFEFE6CF),
  Swatch('strawberry', 0xFFC77A55),
  Swatch('ginger', 0xFFD0661F),
  Swatch('crimson', 0xFF8E1A22),
  Swatch('rose', 0xFFD889A3),
  Swatch('violet', 0xFF5B3A8C),
  Swatch('sapphire', 0xFF2F5FB0),
  Swatch('teal', 0xFF247A78),
  Swatch('emerald', 0xFF2F7A3B),
  Swatch('silver', 0xFFB9BEC6),
];

/// Teintes de peau proposées pour une race (la première est celle du corps
/// dessiné).
List<Swatch> skinsFor(CharacterRace race) => switch (race) {
  CharacterRace.human ||
  CharacterRace.elf ||
  CharacterRace.dwarf ||
  CharacterRace.gnome => naturalSkins,
  CharacterRace.highElf => highElfSkins,
  CharacterRace.orc => orcSkins,
  CharacterRace.goblin => goblinSkins,
  CharacterRace.demon => demonSkins,
  CharacterRace.minotaur => minotaurSkins,
  CharacterRace.undead => undeadSkins,
};

/// Teinte d'une couleur dans une liste, ou `null` si elle n'y est pas.
Swatch? swatchOf(List<Swatch> swatches, int color) {
  for (final swatch in swatches) {
    if (swatch.color == color) return swatch;
  }
  return null;
}
