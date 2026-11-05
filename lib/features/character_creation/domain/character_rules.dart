import 'dart:math';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/character_creation/domain/character_palette.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';

/// Taille (cm) des modèles 3D de substitution, à l'échelle 1 (mesurée sur
/// les fichiers générés par `tool/character/build_characters.py`).
const Map<CharacterRace, Map<CharacterSex, int>> modelHeightCm = {
  CharacterRace.human: {CharacterSex.female: 159, CharacterSex.male: 173},
  CharacterRace.elf: {CharacterSex.female: 187, CharacterSex.male: 200},
  CharacterRace.orc: {CharacterSex.female: 179, CharacterSex.male: 193},
};

/// Fiche de départ pour un sexe et une race.
CharacterSheet defaultSheet({
  CharacterSex sex = CharacterSex.female,
  CharacterRace race = CharacterRace.human,
}) {
  return CharacterSheet(
    sex: sex,
    race: race,
    heightCm: modelHeightCm[race]![sex]!,
    skinColor: skinsFor(race)[race == CharacterRace.orc ? 0 : 2].color,
    hairColor: hairColors[2].color,
  );
}

/// Change la race : taille et teinte de peau sont ramenées dans les valeurs
/// de la nouvelle race si nécessaire.
CharacterSheet changeRace(CharacterSheet sheet, CharacterRace race) {
  if (sheet.race == race) return sheet;
  final skins = skinsFor(race);
  final keepSkin = swatchOf(skins, sheet.skinColor) != null;
  return sheet.copyWith(
    race: race,
    heightCm: modelHeightCm[race]![sheet.sex]!,
    skinColor: keepSkin ? sheet.skinColor : defaultSheet(race: race).skinColor,
  );
}

/// Change le sexe : la taille suit le nouveau modèle.
CharacterSheet changeSex(CharacterSheet sheet, CharacterSex sex) {
  if (sheet.sex == sex) return sheet;
  return sheet.copyWith(sex: sex, heightCm: modelHeightCm[sheet.race]![sex]!);
}

/// Ramène chaque valeur dans ses bornes (fiche importée ou modifiée).
CharacterSheet sanitizeSheet(CharacterSheet sheet, {CharacterConfig? config}) {
  final c = config ?? gameConfig.character;
  return sheet.copyWith(
    corpulence: sheet.corpulence.clamp(0.0, 1.0),
    musculature: sheet.musculature.clamp(0.0, 1.0),
    heightCm: sheet.heightCm.clamp(c.heightMinCm, c.heightMaxCm),
    hairStyle: sheet.hairStyle.clamp(1, hairStyleCount),
  );
}

/// Palier d'un curseur (0 à 4) pour son libellé.
int sliderStep(double value) => (value.clamp(0.0, 1.0) * 4).round();

/// Personnage tiré au hasard (le nom est conservé).
CharacterSheet randomSheet(
  Random random, {
  String name = '',
  CharacterConfig? config,
}) {
  final c = config ?? gameConfig.character;
  final sex = CharacterSex.values[random.nextInt(CharacterSex.values.length)];
  final race =
      CharacterRace.values[random.nextInt(CharacterRace.values.length)];
  final base = modelHeightCm[race]![sex]!;
  final skins = skinsFor(race);
  // Quelques centimètres de plus ou de moins autour de la taille du modèle.
  final height = (base + random.nextInt(17) - 8).clamp(
    c.heightMinCm,
    c.heightMaxCm,
  );
  return CharacterSheet(
    sex: sex,
    race: race,
    name: name,
    corpulence: random.nextInt(5) / 4,
    musculature: random.nextInt(5) / 4,
    heightCm: height,
    skinColor: skins[random.nextInt(skins.length)].color,
    hairColor: hairColors[random.nextInt(hairColors.length)].color,
    hairStyle: random.nextInt(hairStyleCount) + 1,
  );
}
