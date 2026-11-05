import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/character_creation/domain/body_presets.dart';
import 'package:arise/features/character_creation/domain/character_rules.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:arise/features/character_creation/domain/hair_styles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('silhouettes', () {
    for (final sex in CharacterSex.values) {
      test('douze silhouettes distinctes et valides (${sex.name})', () {
        final presets = presetsFor(sex);
        expect(presets, hasLength(12));
        expect(presets.map((p) => p.id).toSet(), hasLength(12));
        expect(
          presets.map((p) => (p.corpulence, p.musculature)).toSet(),
          hasLength(12),
        );
        for (final p in presets) {
          expect(p.corpulence, inInclusiveRange(0, 1));
          expect(p.musculature, inInclusiveRange(0, 1));
        }
      });
    }

    test('appliquer une silhouette ne touche que le corps', () {
      final sheet = defaultSheet().copyWith(name: 'Lyra', hairStyle: 3);
      final swimmer = femalePresets.firstWhere((p) => p.id == 'swimmer');
      final next = applyPreset(sheet, swimmer);
      expect(next.corpulence, swimmer.corpulence);
      expect(next.musculature, swimmer.musculature);
      expect(next.name, 'Lyra');
      expect(next.hairStyle, 3);
      expect(presetOf(next), swimmer);
      expect(presetOf(next.copyWith(corpulence: 0.6)), isNull);
    });
  });

  group('coiffures', () {
    test('chaque coiffure appartient à une famille', () {
      final all = [for (final c in HairCategory.values) ...hairStylesIn(c)]
        ..sort();
      expect(all, [for (var i = 1; i <= hairStyleCount; i++) i]);
    });

    test('favorites : ajout, retrait et limite', () {
      final max = gameConfig.character.favoriteHairstylesMax;
      var sheet = defaultSheet();
      for (var i = 1; i <= max; i++) {
        final r = toggleFavoriteHairStyle(sheet, i);
        expect(r.result, FavoriteToggle.added);
        sheet = r.sheet;
      }
      final full = toggleFavoriteHairStyle(sheet, max + 1);
      expect(full.result, FavoriteToggle.full);
      expect(full.sheet, sheet);

      final removed = toggleFavoriteHairStyle(sheet, 2);
      expect(removed.result, FavoriteToggle.removed);
      expect(removed.sheet.favoriteHairStyles, isNot(contains(2)));
      expect(removed.sheet.favoriteHairStyles, hasLength(max - 1));
    });
  });

  group('visage et bornes', () {
    test('la barbe est réservée aux hommes', () {
      final male = defaultSheet(sex: CharacterSex.male).copyWith(beardStyle: 3);
      expect(changeSex(male, CharacterSex.female).beardStyle, 0);
      expect(
        sanitizeSheet(defaultSheet().copyWith(beardStyle: 4)).beardStyle,
        0,
      );
      expect(sanitizeSheet(male).beardStyle, 3);
    });

    test('ramène les nouveaux réglages dans leurs bornes', () {
      final sheet = sanitizeSheet(
        defaultSheet(sex: CharacterSex.male).copyWith(
          faceJaw: 2,
          faceEars: -1,
          eyebrowStyle: 0,
          beardStyle: 99,
          makeupStyle: -3,
          favoriteHairStyles: [3, 3, 42, 1, 2, 4, 5, 6, 7],
        ),
      );
      expect(sheet.faceJaw, 1);
      expect(sheet.faceEars, 0);
      expect(sheet.eyebrowStyle, 1);
      expect(sheet.beardStyle, beardStyleCount);
      expect(sheet.makeupStyle, 0);
      expect(sheet.favoriteHairStyles, [3, 1, 2, 4, 5]);
    });

    test('une fiche de la version précédente se relit avec des défauts', () {
      final old = {
        'sex': 'male',
        'race': 'orc',
        'heightCm': 190,
        'skinColor': 0xFF6E8B4A,
        'hairColor': 0xFF1C1512,
        'name': 'Grom',
        'corpulence': 0.75,
        'musculature': 1.0,
        'hairStyle': 6,
      };
      final sheet = CharacterSheet.fromJson(old);
      expect(sheet.name, 'Grom');
      expect(sheet.faceJaw, 0.5);
      expect(sheet.eyebrowStyle, 1);
      expect(sheet.beardStyle, 0);
      expect(sheet.beardColor, isNull);
      expect(sheet.favoriteHairStyles, isEmpty);
      expect(sheet.pose, CharacterPose.relaxed);
      expect(sheet.posture, CharacterPosture.neutral);
    });
  });

  group('apparence', () {
    test('visage, pièces et pose', () {
      final sheet = defaultSheet(sex: CharacterSex.male).copyWith(
        faceJaw: 1,
        faceNose: 0,
        eyebrowStyle: 6,
        beardStyle: 2,
        makeupStyle: 4,
        pose: CharacterPose.combat,
        posture: CharacterPosture.upright,
      );
      final a = CharacterAppearance.of(sheet);
      expect(a.morphs['face_jaw_high'], 1);
      expect(a.morphs['face_nose_low'], 1);
      expect(a.morphs['face_mouth_low'], 0);
      expect(a.morphs, hasLength(14));
      expect(a.eyebrowId, 'brow_06');
      expect(a.beardId, 'beard_02');
      expect(a.makeupId, 'makeup_04');
      expect(a.poseId, 'pose_combat');
      expect(a.postureId, 'posture_upright');
      expect(a.beardColor, sheet.hairColor);
      expect(
        CharacterAppearance.of(sheet.copyWith(beardColor: 0xFFE8E4DE))
            .beardColor,
        0xFFE8E4DE,
      );
    });

    test('ni barbe ni maquillage par défaut', () {
      final a = CharacterAppearance.of(defaultSheet());
      expect(a.beardId, isNull);
      expect(a.makeupId, isNull);
      expect(a.eyebrowId, 'brow_01');
      expect(a, CharacterAppearance.of(defaultSheet()));
    });
  });
}
