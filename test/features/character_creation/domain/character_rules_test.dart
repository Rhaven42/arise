import 'dart:math';

import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/character_creation/domain/character_palette.dart';
import 'package:arise/features/character_creation/domain/character_rules.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dix races, chacune avec ses teintes de peau', () {
    expect(CharacterRace.values, hasLength(10));
    expect(CharacterRace.highElf.id, 'high_elf');
    for (final race in CharacterRace.values) {
      final sheet = defaultSheet(race: race);
      expect(swatchOf(skinsFor(race), sheet.skinColor), isNotNull);
      expect(sheet.hairStyle, 1);
    }
  });

  test('changer de race garde les choix compatibles', () {
    final human = defaultSheet().copyWith(
      skinColor: naturalSkins.last.color,
      hairStyle: 4,
    );
    final dwarf = changeRace(human, CharacterRace.dwarf);
    expect(dwarf.skinColor, naturalSkins.last.color);
    expect(dwarf.hairStyle, 4);
    final demon = changeRace(dwarf, CharacterRace.demon);
    expect(swatchOf(demonSkins, demon.skinColor), isNotNull);
  });

  test('passer en femme retire la barbe', () {
    final man = defaultSheet(sex: CharacterSex.male).copyWith(beardStyle: 3);
    expect(changeSex(man, CharacterSex.female).beardStyle, 0);
  });

  test('une ancienne fiche (35 coiffures, peau hors palette) est ramenée', () {
    final sheet = sanitizeSheet(
      defaultSheet(
        sex: CharacterSex.male,
        race: CharacterRace.goblin,
      ).copyWith(hairStyle: 23, beardStyle: 9, skinColor: 0xFF123456),
    );
    expect(sheet.hairStyle, 3);
    expect(sheet.beardStyle, 3);
    expect(sheet.skinColor, defaultSkin(CharacterRace.goblin));
    expect(sanitizeSheet(sheet.copyWith(hairStyle: 0)).hairStyle, 0);
  });

  test('le tirage aléatoire reste valide et garde le nom', () {
    final random = Random(3);
    for (var i = 0; i < 80; i++) {
      final sheet = randomSheet(random, name: 'Kai');
      expect(sheet.name, 'Kai');
      expect(sanitizeSheet(sheet), sheet);
    }
  });

  test('la fiche JSON se relit à l’identique ; les anciennes clés sont '
      'ignorées', () {
    final sheet = randomSheet(Random(1), name: 'Aelin');
    expect(CharacterSheet.fromJson(sheet.toJson()), sheet);
    final old = {
      ...defaultSheet().toJson(),
      'race': 'highElf',
      'heightCm': 180,
      'corpulence': 0.7,
      'faceJaw': 0.2,
      'eyeColor': 0xFF3A2414,
      'makeupStyle': 2,
      'favoriteHairStyles': [3, 4],
    };
    expect(CharacterSheet.fromJson(old).race, CharacterRace.highElf);
    final unknown = {...old, 'race': 'dragon'};
    expect(CharacterSheet.fromJson(unknown).race, CharacterRace.human);
  });

  test('l’apparence nomme le corps, la coiffure et la barbe', () {
    final woman = CharacterAppearance.of(
      defaultSheet(race: CharacterRace.highElf).copyWith(hairStyle: 10),
    );
    expect(woman.bodyId, 'high_elf_female');
    expect(woman.hairId, 'f10');
    expect(woman.beardId, isNull);

    final man = CharacterAppearance.of(
      defaultSheet(
        sex: CharacterSex.male,
        race: CharacterRace.minotaur,
      ).copyWith(hairStyle: 0, beardStyle: 2, beardColor: 0xFF101010),
      loadout: const Loadout(outfitId: 'dawn_plate', weaponId: 'axe_war'),
    );
    expect(man.bodyId, 'minotaur_male');
    expect(man.hairId, isNull);
    expect(man.beardId, 'b02');
    expect(man.beardColor, 0xFF101010);
    expect(man.outfitId, 'dawn_plate');
    expect(man.weaponId, 'axe_war');
    expect(man.adorned(auraColor: 1, shadows: [2]).shadows, [2]);
    expect(
      man,
      CharacterAppearance.of(
        defaultSheet(
          sex: CharacterSex.male,
          race: CharacterRace.minotaur,
        ).copyWith(hairStyle: 0, beardStyle: 2, beardColor: 0xFF101010),
        loadout: const Loadout(outfitId: 'dawn_plate', weaponId: 'axe_war'),
      ),
    );
  });
}
