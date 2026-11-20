import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Apparence à afficher, indépendante du moteur de rendu.
///
/// Les noms (corps, coiffure, barbe, tenue, arme) sont des identifiants
/// stables que chaque moteur relie à ses propres ressources.
@immutable
class CharacterAppearance {
  const CharacterAppearance({
    required this.bodyId,
    required this.skinColor,
    required this.hairColor,
    this.hairId,
    this.beardId,
    this.beardColor,
    this.outfitId,
    this.outfitTint,
    this.weaponId,
    this.pieces = const [],
    this.auraColor,
    this.shadows = const [],
  });

  /// Apparence d'une fiche, avec l'équipement porté ([loadout]).
  factory CharacterAppearance.of(
    CharacterSheet sheet, {
    Loadout loadout = Loadout.none,
  }) {
    String two(int n) => n.toString().padLeft(2, '0');
    final male = sheet.sex == CharacterSex.male;
    return CharacterAppearance(
      bodyId: '${sheet.race.id}_${sheet.sex.name}',
      skinColor: sheet.skinColor,
      hairColor: sheet.hairColor,
      hairId: sheet.hairStyle > 0
          ? '${male ? 'm' : 'f'}${two(sheet.hairStyle)}'
          : null,
      beardId: male && sheet.beardStyle > 0
          ? 'b${two(sheet.beardStyle)}'
          : null,
      beardColor: sheet.beardColor ?? sheet.hairColor,
      outfitId: loadout.outfitId,
      outfitTint: loadout.outfitTint,
      weaponId: loadout.weaponId,
      pieces: loadout.pieces,
    );
  }

  /// Corps : race et sexe (`human_female`, `high_elf_male`…).
  final String bodyId;

  /// Couleurs au format ARGB.
  final int skinColor;
  final int hairColor;

  /// Coiffure (`m01`…`m10`, `f01`…`f10`), ou `null` pour un crâne rasé.
  final String? hairId;

  /// Barbe (`b01`…), ou `null`.
  final String? beardId;
  final int? beardColor;

  /// Tenue portée (sinon, vêtements de base), sa teinte éventuelle.
  final String? outfitId;
  final int? outfitTint;

  /// Arme tenue, ou `null`.
  final String? weaponId;

  /// Pièces séparées (bas, chaussures, haut, gants), dans l'ordre de dessin.
  final List<WornPiece> pieces;

  /// Couleur ARGB de l'aura portée, ou `null`.
  final int? auraColor;

  /// Ombres qui accompagnent le personnage (numéros d'ordre : teinte de
  /// chaque silhouette).
  final List<int> shadows;

  /// Même apparence, avec une aura et des Ombres.
  CharacterAppearance adorned({int? auraColor, List<int> shadows = const []}) =>
      CharacterAppearance(
        bodyId: bodyId,
        skinColor: skinColor,
        hairColor: hairColor,
        hairId: hairId,
        beardId: beardId,
        beardColor: beardColor,
        outfitId: outfitId,
        outfitTint: outfitTint,
        weaponId: weaponId,
        pieces: pieces,
        auraColor: auraColor,
        shadows: shadows,
      );

  @override
  bool operator ==(Object other) =>
      other is CharacterAppearance &&
      other.bodyId == bodyId &&
      other.skinColor == skinColor &&
      other.hairColor == hairColor &&
      other.hairId == hairId &&
      other.beardId == beardId &&
      other.beardColor == beardColor &&
      other.outfitId == outfitId &&
      other.outfitTint == outfitTint &&
      other.weaponId == weaponId &&
      _sameList(other.pieces, pieces) &&
      other.auraColor == auraColor &&
      _sameList(other.shadows, shadows);

  @override
  int get hashCode => Object.hash(
    bodyId,
    skinColor,
    hairColor,
    hairId,
    beardId,
    beardColor,
    outfitId,
    outfitTint,
    weaponId,
    Object.hashAll(pieces),
    auraColor,
    Object.hashAll(shadows),
  );
}

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
