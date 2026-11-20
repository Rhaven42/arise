import 'package:freezed_annotation/freezed_annotation.dart';

part 'character_sheet.freezed.dart';
part 'character_sheet.g.dart';

/// Sexe du personnage : deux corps distincts par race.
enum CharacterSex { female, male }

/// Race du héros : un corps en pixel art par race et par sexe.
enum CharacterRace {
  human,
  elf,
  highElf,
  orc,
  dwarf,
  gnome,
  goblin,
  demon,
  minotaur,
  undead;

  /// Identifiant stable des fichiers et des textes (`snake_case`).
  String get id => switch (this) {
    CharacterRace.highElf => 'high_elf',
    _ => name,
  };
}

/// Fiche du personnage, enregistrée en JSON sur le téléphone.
///
/// Les clés des versions précédentes (silhouette, visage, taille, yeux,
/// maquillage) sont ignorées à la relecture : une fiche ancienne se relit
/// sans erreur et garde race, sexe, couleurs, coiffure, barbe et nom.
@freezed
abstract class CharacterSheet with _$CharacterSheet {
  const factory CharacterSheet({
    required CharacterSex sex,
    @JsonKey(unknownEnumValue: CharacterRace.human) required CharacterRace race,

    /// Couleurs au format ARGB (0xAARRGGBB).
    required int skinColor,
    required int hairColor,
    @Default('') String name,

    /// Coiffure, de 0 (crâne rasé) à [hairStyleCount] ; la liste dépend du
    /// sexe.
    @Default(1) int hairStyle,

    /// Barbe, de 0 (aucune) à [beardStyleCount] ; hommes uniquement.
    @Default(0) int beardStyle,

    /// Couleur de la barbe (ARGB) ; `null` = celle des cheveux.
    int? beardColor,
  }) = _CharacterSheet;

  factory CharacterSheet.fromJson(Map<String, dynamic> json) =>
      _$CharacterSheetFromJson(json);
}

/// Nombre de coiffures par sexe.
const int hairStyleCount = 14;

/// Nombre de barbes (sans compter « aucune »).
const int beardStyleCount = 10;
