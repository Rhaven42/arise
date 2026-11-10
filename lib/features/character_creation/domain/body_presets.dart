import 'package:arise/features/character_creation/domain/character_sheet.dart';

/// Silhouette prête à l'emploi : une corpulence et une musculature.
class BodyPreset {
  const BodyPreset(this.id, this.corpulence, this.musculature);

  /// Identifiant stable (libellé traduit selon le sexe).
  final String id;
  final double corpulence;
  final double musculature;
}

/// Douze silhouettes féminines.
const List<BodyPreset> femalePresets = [
  BodyPreset('delicate', 0, 0),
  BodyPreset('slender', 0.25, 0.25),
  BodyPreset('athletic', 0.5, 0.5),
  BodyPreset('swimmer', 0.25, 0.75),
  BodyPreset('sprinter', 0.5, 0.75),
  BodyPreset('muscular', 0.5, 1),
  BodyPreset('bodybuilder', 0.75, 1),
  BodyPreset('warrior', 0.75, 0.75),
  BodyPreset('round', 0.75, 0.25),
  BodyPreset('sturdy', 1, 0.75),
  BodyPreset('generous', 1, 0.25),
  BodyPreset('hourglass', 0.75, 0.5),
];

/// Douze silhouettes masculines.
const List<BodyPreset> malePresets = [
  BodyPreset('thin', 0, 0),
  BodyPreset('slender', 0.25, 0.25),
  BodyPreset('athletic', 0.5, 0.5),
  BodyPreset('swimmer', 0.25, 0.75),
  BodyPreset('sprinter', 0.5, 0.75),
  BodyPreset('muscular', 0.5, 1),
  BodyPreset('bodybuilder', 0.75, 1),
  BodyPreset('colossus', 1, 1),
  BodyPreset('robust', 0.75, 0.5),
  BodyPreset('stocky', 1, 0.75),
  BodyPreset('imposing', 1, 0.25),
  BodyPreset('v_shape', 0.25, 1),
];

/// Silhouettes proposées pour un sexe.
List<BodyPreset> presetsFor(CharacterSex sex) =>
    sex == CharacterSex.female ? femalePresets : malePresets;

/// Applique une silhouette : seules corpulence et musculature changent.
CharacterSheet applyPreset(CharacterSheet sheet, BodyPreset preset) => sheet
    .copyWith(corpulence: preset.corpulence, musculature: preset.musculature);

/// Silhouette correspondant exactement à la fiche, sinon `null`.
BodyPreset? presetOf(CharacterSheet sheet) {
  for (final preset in presetsFor(sheet.sex)) {
    if (preset.corpulence == sheet.corpulence &&
        preset.musculature == sheet.musculature) {
      return preset;
    }
  }
  return null;
}
