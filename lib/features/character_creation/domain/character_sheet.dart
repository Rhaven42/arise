import 'package:freezed_annotation/freezed_annotation.dart';

part 'character_sheet.freezed.dart';
part 'character_sheet.g.dart';

/// Sexe du personnage : deux maillages distincts.
enum CharacterSex { female, male }

/// Race du royaume d'Arisia.
enum CharacterRace { human, elf, orc }

/// Fiche du personnage, enregistrée en JSON sur le téléphone.
///
/// Les curseurs [corpulence] et [musculature] vont de 0 à 1 (0,5 = milieu).
@freezed
abstract class CharacterSheet with _$CharacterSheet {
  const factory CharacterSheet({
    required CharacterSex sex,
    required CharacterRace race,
    @Default('') String name,
    @Default(0.5) double corpulence,
    @Default(0.5) double musculature,

    /// Taille en centimètres.
    required int heightCm,

    /// Couleurs au format ARGB (0xAARRGGBB).
    required int skinColor,
    required int hairColor,

    /// Coiffure, de 1 à [hairStyleCount].
    @Default(1) int hairStyle,
  }) = _CharacterSheet;

  factory CharacterSheet.fromJson(Map<String, dynamic> json) =>
      _$CharacterSheetFromJson(json);
}

/// Nombre de coiffures disponibles.
const int hairStyleCount = 10;
