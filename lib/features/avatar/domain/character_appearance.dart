import 'package:arise/features/character_creation/domain/character_rules.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Apparence à afficher, indépendante du moteur de rendu.
///
/// Les noms (modèle, formes, coiffure) sont des identifiants stables que
/// chaque moteur relie à ses propres ressources.
@immutable
class CharacterAppearance {
  const CharacterAppearance({
    required this.modelId,
    required this.morphs,
    required this.scale,
    required this.skinColor,
    required this.hairColor,
    required this.hairStyleId,
  });

  /// Construit l'apparence d'une fiche : chaque curseur pilote deux formes
  /// (vers le bas et vers le haut), la taille donne l'échelle du modèle.
  factory CharacterAppearance.of(CharacterSheet sheet) {
    double low(double v) => v < 0.5 ? (0.5 - v) * 2 : 0;
    double high(double v) => v > 0.5 ? (v - 0.5) * 2 : 0;
    return CharacterAppearance(
      modelId: '${sheet.race.name}_${sheet.sex.name}',
      morphs: {
        'corp_low': low(sheet.corpulence),
        'corp_high': high(sheet.corpulence),
        'musc_low': low(sheet.musculature),
        'musc_high': high(sheet.musculature),
      },
      scale: sheet.heightCm / modelHeightCm[sheet.race]![sheet.sex]!,
      skinColor: sheet.skinColor,
      hairColor: sheet.hairColor,
      hairStyleId: 'hair_${sheet.hairStyle.toString().padLeft(2, '0')}',
    );
  }

  final String modelId;
  final Map<String, double> morphs;
  final double scale;
  final int skinColor;
  final int hairColor;
  final String hairStyleId;

  @override
  bool operator ==(Object other) =>
      other is CharacterAppearance &&
      other.modelId == modelId &&
      other.scale == scale &&
      other.skinColor == skinColor &&
      other.hairColor == hairColor &&
      other.hairStyleId == hairStyleId &&
      other.morphs.length == morphs.length &&
      morphs.entries.every((e) => other.morphs[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    modelId,
    scale,
    skinColor,
    hairColor,
    hairStyleId,
    Object.hashAllUnordered(morphs.entries.map((e) => Object.hash(e.key, e.value))),
  );
}
