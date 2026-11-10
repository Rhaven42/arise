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

/// Change le sexe : la taille suit le nouveau modèle ; la barbe est retirée
/// pour un personnage féminin.
CharacterSheet changeSex(CharacterSheet sheet, CharacterSex sex) {
  if (sheet.sex == sex) return sheet;
  return sheet.copyWith(
    sex: sex,
    heightCm: modelHeightCm[sheet.race]![sex]!,
    beardStyle: sex == CharacterSex.female ? 0 : sheet.beardStyle,
  );
}

/// Ramène chaque valeur dans ses bornes (fiche importée ou modifiée).
CharacterSheet sanitizeSheet(CharacterSheet sheet, {CharacterConfig? config}) {
  final c = config ?? gameConfig.character;
  final favorites = <int>[];
  for (final style in sheet.favoriteHairStyles) {
    if (style >= 1 &&
        style <= hairStyleCount &&
        !favorites.contains(style) &&
        favorites.length < c.favoriteHairstylesMax) {
      favorites.add(style);
    }
  }
  return sheet.copyWith(
    corpulence: sheet.corpulence.clamp(0.0, 1.0),
    musculature: sheet.musculature.clamp(0.0, 1.0),
    heightCm: sheet.heightCm.clamp(c.heightMinCm, c.heightMaxCm),
    hairStyle: sheet.hairStyle.clamp(1, hairStyleCount),
    favoriteHairStyles: favorites,
    faceJaw: sheet.faceJaw.clamp(0.0, 1.0),
    faceNose: sheet.faceNose.clamp(0.0, 1.0),
    faceMouth: sheet.faceMouth.clamp(0.0, 1.0),
    faceCheeks: sheet.faceCheeks.clamp(0.0, 1.0),
    faceEars: sheet.faceEars.clamp(0.0, 1.0),
    eyebrowStyle: sheet.eyebrowStyle.clamp(1, eyebrowStyleCount),
    beardStyle: sheet.sex == CharacterSex.female
        ? 0
        : sheet.beardStyle.clamp(0, beardStyleCount),
    makeupStyle: sheet.makeupStyle.clamp(0, makeupStyleCount),
  );
}

/// Palier d'un curseur (0 à 4) pour son libellé.
int sliderStep(double value) => (value.clamp(0.0, 1.0) * 4).round();

/// Personnage tiré au hasard, parmi les coiffures [hairStyles] si elles
/// sont données (le nom, les favoris, la pose et la posture
/// sont conservés : ce sont des réglages d'affichage, pas d'apparence).
CharacterSheet randomSheet(
  Random random, {
  String name = '',
  CharacterSheet? keep,
  List<int>? hairStyles,
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
  double face() => random.nextInt(5) / 4;
  return CharacterSheet(
    sex: sex,
    race: race,
    name: name,
    corpulence: random.nextInt(5) / 4,
    musculature: random.nextInt(5) / 4,
    heightCm: height,
    skinColor: skins[random.nextInt(skins.length)].color,
    hairColor: hairColors[random.nextInt(hairColors.length)].color,
    hairStyle: hairStyles == null || hairStyles.isEmpty
        ? random.nextInt(hairStyleCount) + 1
        : hairStyles[random.nextInt(hairStyles.length)],
    faceJaw: face(),
    faceNose: face(),
    faceMouth: face(),
    faceCheeks: face(),
    faceEars: face(),
    eyeColor: eyeColors[random.nextInt(eyeColors.length)].color,
    eyebrowStyle: random.nextInt(eyebrowStyleCount) + 1,
    beardStyle: sex == CharacterSex.male
        ? random.nextInt(beardStyleCount + 1)
        : 0,
    favoriteHairStyles: keep?.favoriteHairStyles ?? const [],
    pose: keep?.pose ?? CharacterPose.relaxed,
    posture: keep?.posture ?? CharacterPosture.neutral,
  );
}
