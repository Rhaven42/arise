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
/// nouvelle race si nécessaire.
CharacterSheet changeRace(CharacterSheet sheet, CharacterRace race) {
  if (sheet.race == race) return sheet;
  final keepSkin = swatchOf(skinsFor(race), sheet.skinColor) != null;
  return sheet.copyWith(
    race: race,
    skinColor: keepSkin ? sheet.skinColor : defaultSkin(race),
  );
}

/// Change le sexe : la barbe est retirée pour un personnage féminin.
CharacterSheet changeSex(CharacterSheet sheet, CharacterSex sex) {
  if (sheet.sex == sex) return sheet;
  return sheet.copyWith(
    sex: sex,
    beardStyle: sex == CharacterSex.female ? 0 : sheet.beardStyle,
  );
}

/// Ramène chaque valeur dans ses bornes (fiche importée, ancienne version).
///
/// Les anciennes fiches comptaient jusqu'à 35 coiffures : elles retombent
/// dans les 10 coiffures actuelles, dans le même ordre circulaire.
CharacterSheet sanitizeSheet(CharacterSheet sheet) {
  final hair = sheet.hairStyle <= 0
      ? 0
      : (sheet.hairStyle - 1) % hairStyleCount + 1;
  final beard = sheet.beardStyle <= 0
      ? 0
      : (sheet.beardStyle - 1) % beardStyleCount + 1;
  return sheet.copyWith(
    hairStyle: hair,
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
  return CharacterSheet(
    sex: sex,
    race: race,
    name: name,
    skinColor: skins[random.nextInt(skins.length)].color,
    hairColor: hairColors[random.nextInt(hairColors.length)].color,
    hairStyle: hairStyles == null || hairStyles.isEmpty
        ? random.nextInt(hairStyleCount) + 1
        : hairStyles[random.nextInt(hairStyles.length)],
    beardStyle: sex == CharacterSex.male
        ? random.nextInt(beardStyleCount + 1)
        : 0,
  );
}
