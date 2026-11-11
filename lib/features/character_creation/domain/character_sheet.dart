import 'package:freezed_annotation/freezed_annotation.dart';

part 'character_sheet.freezed.dart';
part 'character_sheet.g.dart';

/// Sexe du personnage : deux maillages distincts.
enum CharacterSex { female, male }

/// Race du royaume d'Arisia.
enum CharacterRace { human, elf, orc }

/// Fiche du personnage, enregistrée en JSON sur le téléphone.
///
/// Les curseurs [corpulence], [musculature] et ceux du visage vont de 0 à 1
/// (0,5 = milieu). Chaque champ ajouté a une valeur par défaut : une fiche
/// enregistrée par une version précédente se relit sans perte.
@freezed
abstract class CharacterSheet with _$CharacterSheet {
  const factory CharacterSheet({
    required CharacterSex sex,
    required CharacterRace race,

    /// Taille en centimètres.
    required int heightCm,

    /// Couleurs au format ARGB (0xAARRGGBB).
    required int skinColor,
    required int hairColor,
    @Default('') String name,
    @Default(0.5) double corpulence,
    @Default(0.5) double musculature,

    /// Coiffure, de 1 à [hairStyleCount].
    @Default(1) int hairStyle,

    /// Coiffures favorites (au plus `favoriteHairstylesMax`).
    @Default(<int>[]) List<int> favoriteHairStyles,
    @Default(0.5) double faceJaw,
    @Default(0.5) double faceNose,
    @Default(0.5) double faceMouth,
    @Default(0.5) double faceCheeks,
    @Default(0.5) double faceEars,

    /// Couleur des yeux (ARGB).
    @Default(0xFF5A3A22) int eyeColor,

    /// Sourcils, de 1 à [eyebrowStyleCount].
    @Default(1) int eyebrowStyle,

    /// Barbe, de 0 (aucune) à [beardStyleCount] ; hommes uniquement.
    @Default(0) int beardStyle,

    /// Couleur de la barbe (ARGB) ; `null` = celle des cheveux.
    int? beardColor,

    /// Maquillage, de 0 (aucun) à [makeupStyleCount].
    @Default(0) int makeupStyle,
  }) = _CharacterSheet;

  factory CharacterSheet.fromJson(Map<String, dynamic> json) =>
      _$CharacterSheetFromJson(json);
}

/// Nombre de coiffures disponibles.
const int hairStyleCount = 10;

/// Nombre de styles de sourcils.
const int eyebrowStyleCount = 6;

/// Nombre de barbes (sans compter « aucune »).
const int beardStyleCount = 6;

/// Nombre de maquillages (sans compter « aucun »).
const int makeupStyleCount = 4;
