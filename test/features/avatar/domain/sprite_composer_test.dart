import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/domain/sprite_composer.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:flutter_test/flutter_test.dart';

const Map<String, Object> _head = {
  'skull': [3, 0, 7],
  'brow': 2,
  'neck': 5,
  'profile': [2, 2, 2, 2, 2, 2],
};

/// Toile 10 × 20 : tête au-dessus de la ligne 5, peau marquée par l'alpha.
Map<String, Object> _metaJson() => {
  'canvas': [10, 20],
  'skinAlpha': 254,
  'frontAlpha': 253,
  'bodies': {
    'human_male': {
      'gabarit': 'mm',
      'skull': [3, 0, 7],
      'brow': 2,
      'neck': 5,
      'profile': [2, 2, 2, 2, 2, 2],
      'top': 0,
      'feet': 19,
      'cx': 5,
      'torso': 6,
      'hand': [2, 12],
      'skinRef': [200, 150, 100],
    },
  },
  'templates': {
    'mm': {
      'neck': 5,
      'top': 0,
      'feet': 19,
      'cx': 5,
      'torso': 6,
      'hand': [7, 14],
      'skinRef': [100, 100, 100],
    },
  },
  'hairSources': {'male': _head, 'female': _head, 'beard': _head},
  'weapons': {
    'sword_warden': {
      'size': [1, 4],
      'grip': 0.75,
    },
  },
};

SpriteMeta _meta() => SpriteMeta.fromJson(_metaJson());

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

  test('cheveux et barbe : reflets et ombres resserrés', () {
    // Reflet très clair : éclairci de 35 % de l'écart restant à 0,6 près,
    // jamais blanc.
    expect(tintHairPixel(255, 255, 255, 100, 0xFF5A371E), (
      (90 + 165 * 0.6 * 0.35).round(),
      (55 + 200 * 0.6 * 0.35).round(),
      (30 + 225 * 0.6 * 0.35).round(),
    ));
    // Ombre profonde : 30 % de la couleur au moins.
    expect(tintHairPixel(0, 0, 0, 100, 0xFF5A371E), (27, 17, 9));
  });

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
    // Cou nu de la tenue : peau du gabarit, recolorée à la teinte choisie.
    outfit.pixels.setAll((6 * 10 + 4) * 4, [100, 100, 100, 254]);
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
    expect(_px(out, 4, 6), [200, 150, 106, 255]);
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
    // Épée au repos : tenue à la main (2, 12), lame vers le bas.
    expect(_px(out, 2, 12).take(3), [250, 250, 250]);
    expect(_px(out, 2, 18).take(3), [250, 250, 250]);
    expect(_px(out, 2, 8).take(3), [90, 60, 40]);
    expect(loweredWeapons, containsAll(['sword', 'dagger', 'axe']));
    // Le pommeau dépasse juste au-dessus du poing (3,5 % de 19 px ≈ 1 px).
    expect(_px(out, 2, 11).take(3), [250, 250, 250]);
    expect(_px(out, 2, 10).take(3), [90, 60, 40]);
    expect(loweredWeapons, isNot(contains('staff')));
  });

  test('avec une tenue, le vrai cou reste sous le menton', () {
    final neckBody = RgbaImage(10, 20, Uint8List.fromList(body.pixels));
    // Peau du cou du corps (plus sombre) juste sous le menton.
    neckBody.pixels.setAll((6 * 10 + 4) * 4, [100, 75, 50, 254]);
    final outfit = _fill(10, 20, (x, y) => y > 5 && x >= 3 && x <= 6, [
      10,
      20,
      30,
      255,
    ]);
    outfit.pixels.setAll((6 * 10 + 4) * 4, [100, 100, 100, 254]);
    final out = composer.compose(
      const CharacterAppearance(
        bodyId: 'human_male',
        skinColor: 0xFFC8966A,
        hairColor: 0,
        outfitId: 'awakened_leather',
      ),
      SpriteLayers(body: neckBody, outfit: outfit),
    );
    // La peau du cou du personnage l'emporte sur celle du modèle.
    expect(_px(out, 4, 6), [100, 75, 53, 255]);
    // Le tissu de la tenue reste dessiné.
    expect(_px(out, 3, 6), [10, 20, 30, 255]);
  });

  test('la frange laisse le visage dégagé et les cornes passent devant', () {
    final horned = RgbaImage(10, 20, Uint8List.fromList(body.pixels));
    // Corne à gauche du crâne, sur la ligne 1.
    horned.pixels.setAll((1 * 10 + 2) * 4, [30, 20, 10, 253]);
    // Mèches sur toute la tête, jusqu'au menton.
    final hair = _fill(10, 20, (x, y) => y < 5 && x >= 2 && x <= 7, [
      120,
      60,
      200,
      255,
    ]);
    final out = composer.compose(
      const CharacterAppearance(
        bodyId: 'human_male',
        skinColor: 0xFF00FF00,
        hairColor: 0xFF102030,
        hairId: 'f01',
      ),
      SpriteLayers(body: horned, hair: hair),
    );
    // Au-dessus des sourcils : cheveux.
    expect(_px(out, 4, 1), [16, 32, 48, 255]);
    // Sous les sourcils, sur la peau du visage : pas de mèche.
    expect(_px(out, 4, 4), [0, 255, 0, 255]);
    // Hors de la peau (bord du visage) : la mèche reste.
    expect(_px(out, 2, 4), [16, 32, 48, 255]);
    // Sur la joue, hors du centre du visage : la mèche reste aussi.
    expect(_px(out, 6, 4), [16, 32, 48, 255]);
    // La corne est dessinée par-dessus la coiffure.
    expect(_px(out, 2, 1), [30, 20, 10, 255]);
  });

  test('au-dessus du menton, la barbe ne dépasse pas la joue', () {
    final beard = _fill(10, 20, (x, y) => y >= 3 && y <= 8, [40, 30, 20, 255]);
    final out = composer.compose(
      const CharacterAppearance(
        bodyId: 'human_male',
        skinColor: 0xFFC8963C,
        hairColor: 0xFF000000,
        beardId: 'b01',
      ),
      SpriteLayers(body: body, beard: beard),
    );
    // Ligne 4 (au-dessus du menton) : joue large de 2 pixels autour du
    // centre 5, plus la marge.
    expect(_px(out, 1, 4)[3], 0);
    expect(_px(out, 3, 4), isNot([200, 150, 100, 255]));
    // Ligne 7 (sous le menton) : la barbe tombe librement.
    expect(_px(out, 1, 7)[3], 255);
  });

  test('la tête cible épouse sa forme : échelle par ligne', () {
    const source = HeadFrame(
      skull: Skull(0, 0, 10),
      brow: 4,
      neck: 8,
      profile: [5, 5, 5, 5, 5, 5, 5, 5, 5],
    );
    // Tête deux fois plus large, front plus bas.
    const target = HeadFrame(
      skull: Skull(0, 0, 20),
      brow: 6,
      neck: 14,
      profile: [6, 8, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10],
    );
    final warp = SpriteComposer.headWarp(source, target, 30);
    // Sommet → sourcils : 6 lignes pour 4 (bornées à 0,6–1,4 × l'échelle 2).
    expect(warp.rows[5], closeTo(4 - 0.5 / 1.5 * 1, 1e-9));
    // Crâne plus étroit en haut : échelle 6/5 bornée à 0,75 × 2.
    expect(warp.scales[0], 1.5);
    expect(warp.scales[3], 2);
    // Sous les sourcils, l'échelle du crâne.
    expect(warp.scales[20], 2);

    // Barbe : une seule échelle (celle de la mâchoire), la même à la
    // verticale, calée sur le menton du corps.
    final beard = SpriteComposer.headWarp(source, target, 30, hugJaw: true);
    expect(beard.scales.toSet(), {2});
    expect(beard.rows[14], closeTo(8 + 0.5 / 2, 1e-9));
    expect(beard.rows[20], closeTo(8 + 6.5 / 2, 1e-9));
  });

  test('pièce séparée posée sur le corps, peau nue à la teinte', () {
    // Gant : un pixel de cuir et un pixel de peau nue (alpha 254).
    final glove = _fill(10, 20, (x, y) => y == 12 && x == 2, [40, 30, 20, 255]);
    glove.pixels.setAll((13 * 10 + 2) * 4, [100, 100, 100, 254]);
    const appearance = CharacterAppearance(
      bodyId: 'human_male',
      skinColor: 0xFF00FF00,
      hairColor: 0,
      pieces: [WornPiece('leather_gloves')],
    );
    expect(composer.paths(appearance).pieces, ['pieces/leather_gloves_mm.png']);
    final out = composer.compose(
      appearance,
      SpriteLayers(body: body, pieces: [glove]),
    );
    expect(_px(out, 2, 12), [40, 30, 20, 255]);
    expect(_px(out, 2, 13), [0, 255, 0, 255]);
    // Sans tenue complète, les vêtements de base restent dessous.
    expect(_px(out, 4, 10), [90, 60, 40, 255]);
  });

  test('chaque gant est calé sur la main du personnage', () {
    // Gabarit : mains en x = 3 et 7, ligne 14 ; corps : x = 2 et 8, ligne 12.
    final json = _metaJson()..['pieces'] = {'leather_gloves': 'hands'};
    final gloves = SpriteComposer(SpriteMeta.fromJson(json));
    final glove = _fill(10, 20, (x, y) => y == 14 && (x == 3 || x == 7), [
      40,
      30,
      20,
      255,
    ]);
    final out = gloves.compose(
      const CharacterAppearance(
        bodyId: 'human_male',
        skinColor: 0xFF00FF00,
        hairColor: 0,
        pieces: [WornPiece('leather_gloves')],
      ),
      SpriteLayers(body: body, pieces: [glove]),
    );
    expect(_px(out, 2, 12), [40, 30, 20, 255]);
    expect(_px(out, 8, 12), [40, 30, 20, 255]);
    // Plus rien à l'emplacement des mains du gabarit.
    expect(_px(out, 3, 14), isNot([40, 30, 20, 255]));
  });

  test('une botte couvre le pied du corps, sabots compris', () {
    // Pied gauche du gabarit : 4 × 4 pixels ; celui du corps : 6 × 6.
    final json = _metaJson()..['pieces'] = {'iron_greaves': 'feet'};
    ((json['templates']! as Map)['mm'] as Map)['feetBoxes'] = [
      [2, 16, 6, 20],
      [6, 16, 8, 20],
    ];
    ((json['bodies']! as Map)['human_male'] as Map)['feetBoxes'] = [
      [1, 14, 7, 20],
      [7, 14, 10, 20],
    ];
    final boots = SpriteComposer(SpriteMeta.fromJson(json));
    final boot = _fill(10, 20, (x, y) => x >= 2 && x < 6 && y >= 16, [
      200,
      200,
      210,
      255,
    ]);
    final out = boots.compose(
      const CharacterAppearance(
        bodyId: 'human_male',
        skinColor: 0xFF00FF00,
        hairColor: 0,
        pieces: [WornPiece('iron_greaves')],
      ),
      SpriteLayers(body: body, pieces: [boot]),
    );
    expect(
      extremityScale(
        const Box(2, 16, 6, 20),
        const Box(1, 14, 7, 20),
        feet: true,
      ),
      1.5,
    );
    for (final (x, y) in [(1, 14), (6, 14), (1, 19), (6, 19)]) {
      expect(_px(out, x, y), [200, 200, 210, 255], reason: '($x, $y)');
    }
  });

  test('un gant est peint sur la main du personnage, à sa forme', () {
    final json = _metaJson()
      ..['pieces'] = {'leather_gloves': 'hands'}
      ..['gloves'] = {
        'leather_gloves': {
          'cuff': 0,
          'fingers': true,
          'ramp': [
            [10, 10, 10],
            [50, 50, 50],
          ],
          'cuffRamp': <List<int>>[],
        },
      };
    ((json['bodies']! as Map)['human_male'] as Map)
      ..['hand'] = [2, 11]
      ..['handBoxes'] = [
        [1, 10, 3, 13],
        [7, 10, 9, 13],
      ];
    final gloves = SpriteComposer(SpriteMeta.fromJson(json));
    // Corps : chemise, mains nues (peau) en x 1-2 et 7-8, lignes 10 à 12.
    final hands = _fill(10, 20, (x, y) => x >= 1 && x <= 8, [90, 60, 40, 255]);
    for (var y = 10; y <= 12; y++) {
      for (final x in [1, 2, 7, 8]) {
        hands.pixels.setAll((y * 10 + x) * 4, [200, 150, 100, 254]);
      }
    }
    final out = gloves.compose(
      const CharacterAppearance(
        bodyId: 'human_male',
        skinColor: 0xFFC8963C,
        hairColor: 0,
        pieces: [WornPiece('leather_gloves')],
      ),
      SpriteLayers(body: hands, pieces: [RgbaImage(10, 20)]),
    );
    for (final (x, y) in [(1, 11), (2, 12), (7, 10), (8, 11)]) {
      expect(
        _px(out, x, y),
        anyOf(equals([10, 10, 10, 255]), equals([50, 50, 50, 255])),
        reason: '($x, $y)',
      );
    }
    // La chemise entre les mains ne change pas.
    expect(_px(out, 4, 11), [90, 60, 40, 255]);
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
    // Barbes dessinées sur le visage de la race, pour les hommes seulement.
    expect(meta.ownBeard('goblin_male'), isTrue);
    expect(meta.ownBeard('goblin_female'), isFalse);
    expect(meta.ownBeard('human_male'), isFalse);
    String? beardOf(String body) => real
        .paths(
          CharacterAppearance(
            bodyId: body,
            skinColor: 0,
            hairColor: 0,
            beardId: 'b02',
          ),
        )
        .beard;
    expect(beardOf('goblin_male'), 'beards/goblin/b02.png');
    expect(beardOf('high_elf_male'), 'beards/b02.png');
    for (final w in weaponCatalog) {
      expect(meta.weapons, contains(w.id));
      expect(weaponLength, contains(w.id.split('_').first));
    }
  });

  test('chaque dossier de sprites est déclaré dans pubspec.yaml', () {
    // Flutter n'embarque pas les sous-dossiers : un dossier oublié = calques
    // introuvables dans l'appli.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final dirs = {
      for (final f in Directory('assets/sprites').listSync(recursive: true))
        if (f is File && f.path.endsWith('.png'))
          '${f.parent.path.replaceAll(r'\\', '/')}/',
    };
    expect(dirs, isNotEmpty);
    for (final dir in dirs) {
      expect(pubspec, contains('- $dir\n'), reason: dir);
    }
  });
}
