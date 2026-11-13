import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';

/// Famille de coiffures, pour filtrer la liste.
enum HairCategory { short, tied, long }

/// Famille de chaque coiffure (1 à [hairStyleCount]).
const Map<int, HairCategory> hairStyleCategory = {
  1: HairCategory.short,
  2: HairCategory.tied,
  3: HairCategory.tied,
  4: HairCategory.tied,
  5: HairCategory.long,
  6: HairCategory.short,
  7: HairCategory.short,
  8: HairCategory.tied,
  9: HairCategory.long,
  10: HairCategory.short,
  // Coiffures fournies (pieces.json, 13/11/2026).
  11: HairCategory.short,
  12: HairCategory.short,
  13: HairCategory.tied,
  14: HairCategory.long,
  15: HairCategory.tied,
  16: HairCategory.tied,
  17: HairCategory.tied,
  18: HairCategory.tied,
  19: HairCategory.short,
  20: HairCategory.tied,
  21: HairCategory.short,
  22: HairCategory.short,
  23: HairCategory.short,
  24: HairCategory.long,
  25: HairCategory.long,
  26: HairCategory.tied,
  27: HairCategory.short,
  28: HairCategory.long,
  29: HairCategory.short,
  30: HairCategory.tied,
  31: HairCategory.short,
  32: HairCategory.short,
  33: HairCategory.long,
  34: HairCategory.short,
  35: HairCategory.short,
};

/// Coiffures d'une famille, dans l'ordre.
List<int> hairStylesIn(HairCategory category) => [
  for (var i = 1; i <= hairStyleCount; i++)
    if (hairStyleCategory[i] == category) i,
];

/// Résultat d'un appui sur l'étoile d'une coiffure.
enum FavoriteToggle { added, removed, full }

/// Ajoute ou retire une coiffure des favorites ; refuse l'ajout quand la
/// liste est pleine.
({CharacterSheet sheet, FavoriteToggle result}) toggleFavoriteHairStyle(
  CharacterSheet sheet,
  int style, {
  CharacterConfig? config,
}) {
  final max = (config ?? gameConfig.character).favoriteHairstylesMax;
  final favorites = sheet.favoriteHairStyles;
  if (favorites.contains(style)) {
    return (
      sheet: sheet.copyWith(
        favoriteHairStyles: [
          for (final f in favorites)
            if (f != style) f,
        ],
      ),
      result: FavoriteToggle.removed,
    );
  }
  if (favorites.length >= max) {
    return (sheet: sheet, result: FavoriteToggle.full);
  }
  return (
    sheet: sheet.copyWith(favoriteHairStyles: [...favorites, style]),
    result: FavoriteToggle.added,
  );
}
