import 'dart:math';

import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/character_creation/domain/character_palette.dart';
import 'package:arise/features/character_creation/domain/character_rules.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la fiche de départ a la taille du modèle et une teinte de la race', () {
    final orc = defaultSheet(sex: CharacterSex.male, race: CharacterRace.orc);
    expect(orc.heightCm, modelHeightCm[CharacterRace.orc]![CharacterSex.male]);
    expect(swatchOf(orcSkins, orc.skinColor), isNotNull);
    expect(orc.corpulence, 0.5);
    expect(orc.hairStyle, 1);
  });

  test('changer de race garde les choix compatibles', () {
    final human = defaultSheet().copyWith(
      skinColor: naturalSkins.last.color,
      hairStyle: 4,
    );
    final elf = changeRace(human, CharacterRace.elf);
    expect(elf.skinColor, naturalSkins.last.color);
    expect(elf.hairStyle, 4);
    final orc = changeRace(elf, CharacterRace.orc);
    expect(swatchOf(orcSkins, orc.skinColor), isNotNull);
    expect(changeSex(orc, CharacterSex.male).heightCm, 193);
  });

  test('ramène les valeurs dans leurs bornes', () {
    final sheet = sanitizeSheet(
      defaultSheet().copyWith(
        corpulence: 3,
        musculature: -1,
        heightCm: 300,
        hairStyle: 42,
      ),
    );
    expect(sheet.corpulence, 1);
    expect(sheet.musculature, 0);
    expect(sheet.heightCm, 205);
    expect(sheet.hairStyle, hairStyleCount);
  });

  test('cinq paliers de libellés par curseur', () {
    expect(sliderStep(0), 0);
    expect(sliderStep(0.3), 1);
    expect(sliderStep(0.5), 2);
    expect(sliderStep(0.8), 3);
    expect(sliderStep(1), 4);
  });

  test('le tirage aléatoire reste valide et garde le nom', () {
    final random = Random(3);
    for (var i = 0; i < 50; i++) {
      final sheet = randomSheet(random, name: 'Kai');
      expect(sheet.name, 'Kai');
      expect(sanitizeSheet(sheet), sheet);
      expect(swatchOf(skinsFor(sheet.race), sheet.skinColor), isNotNull);
    }
  });

  test('la fiche JSON se relit à l’identique', () {
    final sheet = randomSheet(Random(1), name: 'Aelin');
    expect(CharacterSheet.fromJson(sheet.toJson()), sheet);
    expect(sheet.toJson()['race'], isA<String>());
  });

  test('l’apparence pilote les formes du modèle', () {
    final base = CharacterAppearance.of(defaultSheet());
    expect(base.modelId, 'human_female');
    expect(base.morphs.values.every((v) => v == 0), isTrue);
    expect(base.scale, 1);
    expect(base.hairStyleId, 'hair_01');

    final big = CharacterAppearance.of(
      defaultSheet(race: CharacterRace.elf).copyWith(
        corpulence: 1,
        musculature: 0.25,
        heightCm: 150,
        hairStyle: 10,
      ),
    );
    expect(big.modelId, 'elf_female');
    expect(big.morphs['corp_high'], 1);
    expect(big.morphs['corp_low'], 0);
    expect(big.morphs['musc_low'], 0.5);
    expect(big.scale, closeTo(150 / 187, 1e-9));
    expect(big.hairStyleId, 'hair_10');
  });

  test('une fiche Haut-elfe (race retirée) se relit comme Elfe', () {
    final json = defaultSheet(race: CharacterRace.elf).toJson()
      ..['race'] = 'highElf';
    expect(CharacterSheet.fromJson(json).race, CharacterRace.elf);
    expect(CharacterRace.orc.id, 'orc');
  });
}
