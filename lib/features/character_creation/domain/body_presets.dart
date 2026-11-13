import 'package:arise/features/character_creation/domain/character_sheet.dart';

/// Silhouette prête à l'emploi : une corpulence et une musculature.
class BodyPreset {
  const BodyPreset(this.id, this.corpulence, this.musculature);

  /// Identifiant stable (libellé traduit selon le sexe).
  final String id;
  final double corpulence;
  final double musculature;
}

/// Quatre silhouettes, les mêmes pour chaque sexe (13/11/2026) : élancée,
/// équilibrée, robuste, puissante.
const List<BodyPreset> bodyPresets = [
  BodyPreset('slim', 0.15, 0.3),
  BodyPreset('normal', 0.5, 0.5),
  BodyPreset('heavy', 0.95, 0.5),
  BodyPreset('muscular', 0.5, 0.95),
];

/// Silhouettes proposées pour un sexe.
List<BodyPreset> presetsFor(CharacterSex sex) => bodyPresets;

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
