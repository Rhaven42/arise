import 'dart:convert';
import 'dart:io';

import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/domain/sprite_composer.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:flutter_test/flutter_test.dart';

/// Toile 10 × 20 : tête au-dessus de la ligne 5, peau marquée par l'alpha.
SpriteMeta _meta() => SpriteMeta.fromJson({
  'canvas': [10, 20],
  'skinAlpha': 254,
  'bodies': {
    'human_male': {
      'gabarit': 'mm',
      'skull': [3, 0, 7],
      'neck': 5,
      'top': 0,
      'feet': 19,
      'cx': 5,
      'torso': 6,
      'hand': [2, 12],
      'skinRef': [200, 150, 100],
    },
  },
  'templates': {
    'mm': {'neck': 5, 'top': 0, 'feet': 19, 'cx': 5, 'torso': 6},
  },
  'hairSources': {
    'male': [3, 0, 7],
    'female': [3, 0, 7],
    'beard': [3, 0, 7],
  },
  'weapons': {
    'sword_warden': {
      'size': [1, 4],
      'grip': 0.75,
    },
  },
});

RgbaImage _fill(int w, int h, bool Function(int x, int y) on, List<int> rgba) {
  final img = RgbaImage(w, h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (!on(x, y)) continue;
      final i = (y * w + x) * 4;
      img.pixels.setAll(i, rgba);
    }
  }
  return img;
}

List<int> _px(RgbaImage img, int x, int y) {
  final i = (y * img.width + x) * 4;
  return img.pixels.sublist(i, i + 4);
}

void main() {
  final composer = SpriteComposer(_meta());
  // Corps : peau sur la tête (lignes 0-4) et les mains, chemise ailleurs.
  final body = _fill(10, 20, (x, y) => x >= 2 && x <= 7, [90, 60, 40, 255]);
  for (var y = 0; y < 5; y++) {
    for (var x = 3; x < 7; x++) {
      body.pixels.setAll((y * 10 + x) * 4, [200, 150, 100, 254]);
    }
  }

  test('la peau prend la teinte choisie, avec le même modelé', () {
    expect(tintPixel(200, 150, 100, luminanceOf(200, 150, 100), 0xFFC8963C), (
      200,
      150,
      60,
    ));
    final out = composer.compose(
      const CharacterAppearance(
        bodyId: 'human_male',
        skinColor: 0xFF00FF00,
        hairColor: 0,
      ),
      SpriteLayers(body: body),
    );
    expect(_px(out, 4, 2), [0, 255, 0, 255]);
    // La chemise ne change pas.
    expect(_px(out, 4, 10), [90, 60, 40, 255]);
  });

  test('une tenue remplace les vêtements sous le cou, pas la tête', () {
    final outfit = _fill(10, 20, (x, y) => y > 5 && x >= 3 && x <= 6, [
      10,
      20,
      30,
      255,
    ]);
    final out = composer.compose(
      const CharacterAppearance(
        bodyId: 'human_male',
        skinColor: 0xFFC8966A,
        hairColor: 0,
        outfitId: 'awakened_leather',
      ),
      SpriteLayers(body: body, outfit: outfit),
    );
    expect(_px(out, 4, 10), [10, 20, 30, 255]);
    // Hors de la tenue, les vêtements de base ont disparu.
    expect(_px(out, 2, 10)[3], 0);
    expect(_px(out, 4, 2)[3], 255);
  });

  test('coiffure posée sur le crâne et arme dans la main', () {
    final hair = _fill(10, 20, (x, y) => y == 0 && x >= 3 && x <= 6, [
      120,
      60,
      200,
      255,
    ]);
    final weapon = _fill(1, 4, (x, y) => true, [250, 250, 250, 255]);
    final out = composer.compose(
      const CharacterAppearance(
        bodyId: 'human_male',
        skinColor: 0xFFC8966A,
        hairColor: 0xFF102030,
        hairId: 'm01',
        weaponId: 'sword_warden',
      ),
      SpriteLayers(body: body, hair: hair, weapon: weapon),
    );
    // Cheveux recolorés (luminance de référence = la leur).
    expect(_px(out, 4, 0), [16, 32, 48, 255]);
    // L'arme est tenue à la main (2, 12) et dépasse au-dessus.
    expect(_px(out, 2, 12).take(3), [250, 250, 250]);
    expect(_px(out, 2, 4)[3], 255);
  });

  test('les repères réels couvrent chaque race, tenue et arme', () {
    final meta = SpriteMeta.fromJson(
      jsonDecode(File('assets/sprites/sprites.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final real = SpriteComposer(meta);
    for (final race in CharacterRace.values) {
      for (final sex in CharacterSex.values) {
        final id = '${race.id}_${sex.name}';
        expect(meta.bodies, contains(id));
        for (final item in [...outfitCatalog, ...bossRewardItems]) {
          final p = real.paths(
            CharacterAppearance(
              bodyId: id,
              skinColor: 0,
              hairColor: 0,
              hairId: sex == CharacterSex.male ? 'm10' : 'f10',
              beardId: 'b06',
              outfitId: item.spriteId,
              weaponId: weaponCatalog.first.id,
            ),
          );
          for (final path in [p.body, p.outfit, p.hair, p.beard, p.weapon]) {
            expect(
              File('assets/sprites/$path').existsSync(),
              isTrue,
              reason: path,
            );
          }
        }
      }
    }
    for (final w in weaponCatalog) {
      expect(meta.weapons, contains(w.id));
      expect(weaponLength, contains(w.id.split('_').first));
    }
  });
}
