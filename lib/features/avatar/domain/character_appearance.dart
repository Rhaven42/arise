import 'package:arise/features/character_creation/domain/character_rules.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Apparence à afficher, indépendante du moteur de rendu.
///
/// Les noms (modèle, formes, pièces, poses) sont des identifiants stables
/// que chaque moteur relie à ses propres ressources.
@immutable
class CharacterAppearance {
  const CharacterAppearance({
    required this.modelId,
    required this.morphs,
    required this.scale,
    required this.skinColor,
    required this.hairColor,
    required this.hairStyleId,
    this.eyeColor = 0xFF5A3A22,
    this.beardColor = 0xFF3B2416,
    this.eyebrowId = 'brow_01',
    this.beardId,
    this.makeupId,
    this.poseId = 'pose_relaxed',
    this.postureId = 'posture_neutral',
    this.itemNodes = const [],
    this.hiddenOutfit = const [],
    this.dyes = const {},
  });

  /// Construit l'apparence d'une fiche : chaque curseur pilote deux formes
  /// (vers le bas et vers le haut), la taille donne l'échelle du modèle.
  /// L'équipement porté ([loadout]) s'affiche par-dessus le corps et masque
  /// les pièces de la tenue de départ qu'il remplace.
  factory CharacterAppearance.of(
    CharacterSheet sheet, {
    Loadout loadout = Loadout.none,
  }) {
    double low(double v) => v < 0.5 ? (0.5 - v) * 2 : 0;
    double high(double v) => v > 0.5 ? (v - 0.5) * 2 : 0;
    String two(int n) => n.toString().padLeft(2, '0');
    final sliders = {
      'corp': sheet.corpulence,
      'musc': sheet.musculature,
      'face_jaw': sheet.faceJaw,
      'face_nose': sheet.faceNose,
      'face_mouth': sheet.faceMouth,
      'face_cheeks': sheet.faceCheeks,
      'face_ears': sheet.faceEars,
    };
    final beard = sheet.sex == CharacterSex.male ? sheet.beardStyle : 0;
    return CharacterAppearance(
      modelId: '${sheet.race.name}_${sheet.sex.name}',
      morphs: {
        for (final e in sliders.entries) ...{
          '${e.key}_low': low(e.value),
          '${e.key}_high': high(e.value),
        },
      },
      scale: sheet.heightCm / modelHeightCm[sheet.race]![sheet.sex]!,
      skinColor: sheet.skinColor,
      hairColor: sheet.hairColor,
      hairStyleId: loadout.hidesHair ? '' : 'hair_${two(sheet.hairStyle)}',
      eyeColor: sheet.eyeColor,
      beardColor: sheet.beardColor ?? sheet.hairColor,
      eyebrowId: 'brow_${two(sheet.eyebrowStyle)}',
      beardId: beard > 0 ? 'beard_${two(beard)}' : null,
      makeupId: sheet.makeupStyle > 0
          ? 'makeup_${two(sheet.makeupStyle)}'
          : null,
      poseId: 'pose_${sheet.pose.name}',
      postureId: 'posture_${sheet.posture.name}',
      itemNodes: loadout.itemNodes,
      hiddenOutfit: loadout.hiddenOutfit,
      dyes: loadout.dyes,
    );
  }

  final String modelId;
  final Map<String, double> morphs;
  final double scale;
  final int skinColor;
  final int hairColor;

  /// Coiffure visible (vide si un casque ou une capuche la cache).
  final String hairStyleId;
  final int eyeColor;
  final int beardColor;
  final String eyebrowId;

  /// Barbe visible, ou `null`.
  final String? beardId;

  /// Maquillage visible, ou `null`.
  final String? makeupId;
  final String poseId;
  final String postureId;

  /// Pièces d'équipement visibles.
  final List<String> itemNodes;

  /// Pièces de la tenue de départ masquées.
  final List<String> hiddenOutfit;

  /// Couleur par matériau teint.
  final Map<String, int> dyes;

  @override
  bool operator ==(Object other) =>
      other is CharacterAppearance &&
      other.modelId == modelId &&
      other.scale == scale &&
      other.skinColor == skinColor &&
      other.hairColor == hairColor &&
      other.hairStyleId == hairStyleId &&
      other.eyeColor == eyeColor &&
      other.beardColor == beardColor &&
      other.eyebrowId == eyebrowId &&
      other.beardId == beardId &&
      other.makeupId == makeupId &&
      other.poseId == poseId &&
      other.postureId == postureId &&
      _sameList(other.itemNodes, itemNodes) &&
      _sameList(other.hiddenOutfit, hiddenOutfit) &&
      other.dyes.length == dyes.length &&
      dyes.entries.every((e) => other.dyes[e.key] == e.value) &&
      other.morphs.length == morphs.length &&
      morphs.entries.every((e) => other.morphs[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    modelId,
    scale,
    skinColor,
    hairColor,
    hairStyleId,
    eyeColor,
    beardColor,
    eyebrowId,
    beardId,
    makeupId,
    poseId,
    postureId,
    Object.hashAll(itemNodes),
    Object.hashAll(hiddenOutfit),
    Object.hashAllUnordered(
      dyes.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(
      morphs.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
