import 'dart:math';

import 'package:arise/features/character_creation/domain/character_palette.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';

/// Teinte de peau de départ de chaque race (proche du corps dessiné).
const Map<CharacterRace, int> defaultSkinIndex = {
  CharacterRace.human: 2,
  CharacterRace.elf: 2,
  CharacterRace.highElf: 0,
  CharacterRace.orc: 0,
  CharacterRace.dwarf: 3,
  CharacterRace.gnome: 2,
  CharacterRace.goblin: 0,
  CharacterRace.demon: 0,
  CharacterRace.minotaur: 0,
  CharacterRace.undead: 0,
};

/// Coiffures masquées pour une race et un sexe : elles se posent mal sur sa
/// tête (cornes du minotaure et de la démone, grosses têtes des gnomes).
const Map<CharacterRace, Map<CharacterSex, Set<int>>> hiddenHairStyles = {
  CharacterRace.minotaur: {
    CharacterSex.male: {1, 3, 5, 6, 9, 10, 11, 12},
    CharacterSex.female: {4, 6, 7, 12},
  },
  CharacterRace.demon: {
    CharacterSex.male: {5, 12},
    CharacterSex.female: {4, 6},
  },
  CharacterRace.dwarf: {
    CharacterSex.female: {7},
  },
  CharacterRace.gnome: {
    CharacterSex.female: {6},
  },
};

/// Coiffures retirées pour toutes les races (le dessin laisse le crâne nu).
const Map<CharacterSex, Set<int>> retiredHairStyles = {
  CharacterSex.female: {13},
};

/// La coiffure [style] se porte-t-elle sur cette race et ce sexe ?
bool hairStyleFits(CharacterRace race, CharacterSex sex, int style) =>
    style == 0 ||
    !((retiredHairStyles[sex]?.contains(style) ?? false) ||
        (hiddenHairStyles[race]?[sex]?.contains(style) ?? false));

/// Coiffures proposées pour une race et un sexe (0 : crâne rasé).
List<int> hairStylesFor(CharacterRace race, CharacterSex sex) => [
  for (var style = 0; style <= hairStyleCount; style++)
    if (hairStyleFits(race, sex, style)) style,
];

/// Teinte de peau de départ d'une race.
int defaultSkin(CharacterRace race) =>
    skinsFor(race)[defaultSkinIndex[race]!].color;

/// Fiche de départ pour un sexe et une race.
CharacterSheet defaultSheet({
  CharacterSex sex = CharacterSex.female,
  CharacterRace race = CharacterRace.human,
}) => CharacterSheet(
  sex: sex,
  race: race,
  skinColor: defaultSkin(race),
  hairColor: hairColors[2].color,
);

/// Change la race : la teinte de peau est ramenée dans celles de la
/// nouvelle race si nécessaire, une coiffure qui ne lui va pas est retirée.
CharacterSheet changeRace(CharacterSheet sheet, CharacterRace race) {
  if (sheet.race == race) return sheet;
  final keepSkin = swatchOf(skinsFor(race), sheet.skinColor) != null;
  return sheet.copyWith(
    race: race,
    skinColor: keepSkin ? sheet.skinColor : defaultSkin(race),
    hairStyle: hairStyleFits(race, sheet.sex, sheet.hairStyle)
        ? sheet.hairStyle
        : 0,
  );
}

/// Change le sexe : la barbe est retirée pour un personnage féminin.
CharacterSheet changeSex(CharacterSheet sheet, CharacterSex sex) {
  if (sheet.sex == sex) return sheet;
  return sheet.copyWith(
    sex: sex,
    beardStyle: sex == CharacterSex.female ? 0 : sheet.beardStyle,
    hairStyle: hairStyleFits(sheet.race, sex, sheet.hairStyle)
        ? sheet.hairStyle
        : 0,
  );
}

/// Ramène chaque valeur dans ses bornes (fiche importée, ancienne version).
///
/// Les anciennes fiches comptaient jusqu'à 35 coiffures : elles retombent
/// dans les coiffures actuelles, dans le même ordre circulaire ; une
/// coiffure masquée pour la race devient un crâne rasé.
CharacterSheet sanitizeSheet(CharacterSheet sheet) {
  final hair = sheet.hairStyle <= 0
      ? 0
      : (sheet.hairStyle - 1) % hairStyleCount + 1;
  final beard = sheet.beardStyle <= 0
      ? 0
      : (sheet.beardStyle - 1) % beardStyleCount + 1;
  return sheet.copyWith(
    hairStyle: hairStyleFits(sheet.race, sheet.sex, hair) ? hair : 0,
    beardStyle: sheet.sex == CharacterSex.female ? 0 : beard,
    skinColor: swatchOf(skinsFor(sheet.race), sheet.skinColor) == null
        ? defaultSkin(sheet.race)
        : sheet.skinColor,
  );
}

/// Personnage tiré au hasard, parmi les coiffures [hairStyles] si elles
/// sont données (le nom est conservé).
CharacterSheet randomSheet(
  Random random, {
  String name = '',
  List<int>? hairStyles,
}) {
  final sex = CharacterSex.values[random.nextInt(CharacterSex.values.length)];
  final race =
      CharacterRace.values[random.nextInt(CharacterRace.values.length)];
  final skins = skinsFor(race);
  final styles = [
    for (final style in hairStyles ?? hairStylesFor(race, sex).skip(1))
      if (style > 0 && hairStyleFits(race, sex, style)) style,
  ];
  return CharacterSheet(
    sex: sex,
    race: race,
    name: name,
    skinColor: skins[random.nextInt(skins.length)].color,
    hairColor: hairColors[random.nextInt(hairColors.length)].color,
    hairStyle: styles.isEmpty ? 0 : styles[random.nextInt(styles.length)],
    beardStyle: sex == CharacterSex.male
        ? random.nextInt(beardStyleCount + 1)
        : 0,
  );
}
