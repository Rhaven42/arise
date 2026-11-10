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
  9: HairCategory.short,
  10: HairCategory.long,
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
