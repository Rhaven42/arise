import 'dart:math' as math;
import 'dart:typed_data';

import 'package:arise/features/avatar/domain/character_appearance.dart';

/// Image RGBA non prémultipliée (4 octets par pixel, ligne par ligne).
class RgbaImage {
  RgbaImage(this.width, this.height, [Uint8List? pixels])
    : pixels = pixels ?? Uint8List(width * height * 4);

  final int width;
  final int height;
  final Uint8List pixels;

  int alphaAt(int x, int y) => pixels[(y * width + x) * 4 + 3];
}

/// Crâne d'un corps : bord gauche, sommet, bord droit (pixels de la toile).
class Skull {
  const Skull(this.left, this.top, this.right);

  factory Skull.fromJson(List<dynamic> json) => Skull(
    (json[0] as num).toDouble(),
    (json[1] as num).toDouble(),
    (json[2] as num).toDouble(),
  );

  final double left;
  final double top;
  final double right;

  double get width => right - left;
  double get centre => (left + right) / 2;
}

/// Repères d'une tête : crâne, sourcils, menton et demi-largeur de la tête
/// à chaque ligne, du sommet du crâne au menton (les coiffures et les barbes
/// épousent la tête).
class HeadFrame {
  const HeadFrame({
    required this.skull,
    required this.brow,
    required this.neck,
    required this.profile,
  });

  factory HeadFrame.fromJson(Map<String, dynamic> json) => HeadFrame(
    skull: Skull.fromJson(json['skull'] as List<dynamic>),
    brow: (json['brow'] as num).toDouble(),
    neck: (json['neck'] as num).toDouble(),
    profile: [
      for (final w in json['profile'] as List<dynamic>) (w as num).toDouble(),
    ],
  );

  final Skull skull;

  /// Ligne des sourcils : la frange s'arrête au-dessus.
  final double brow;

  /// Ligne du menton.
  final double neck;

  /// Demi-largeur de la tête, une valeur par ligne depuis le sommet du crâne.
  final List<double> profile;

  /// Demi-largeur mesurée à la ligne [y], ou `null` hors de la tête (moins
  /// de la moitié du demi-crâne).
  double? halfWidthAt(double y) {
    final i = y.floor() - skull.top.truncate();
    if (i < 0 || i >= profile.length) return null;
    final w = profile[i];
    return w >= 0.25 * skull.width ? w : null;
  }
}

/// Boîte d'un pied ou d'une main (bords gauche, haut, droit, bas exclus).
class Box {
  const Box(this.left, this.top, this.right, this.bottom);

  factory Box.fromJson(List<dynamic> v) => Box(
    (v[0] as num).toDouble(),
    (v[1] as num).toDouble(),
    (v[2] as num).toDouble(),
    (v[3] as num).toDouble(),
  );

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;
  double get centreX => (left + right) / 2;
  double get centreY => (top + bottom) / 2;
}

/// Repères d'un corps ou d'un gabarit de tenue.
class BodyFrame {
  const BodyFrame({
    required this.neck,
    required this.top,
    required this.feet,
    required this.centreX,
    required this.torso,
    double? chin,
    this.feetBoxes = const [],
    this.handBoxes = const [],
  }) : chin = chin ?? neck;

  factory BodyFrame.fromJson(Map<String, dynamic> json) {
    List<Box> boxes(String key) => [
      for (final v in json[key] as List<dynamic>? ?? const [])
        Box.fromJson(v as List<dynamic>),
    ];
    return BodyFrame(
      neck: (json['neck'] as num).toDouble(),
      chin: (json['chin'] as num?)?.toDouble(),
      top: (json['top'] as num).toDouble(),
      feet: (json['feet'] as num).toDouble(),
      centreX: (json['cx'] as num).toDouble(),
      torso: (json['torso'] as num).toDouble(),
      feetBoxes: boxes('feetBoxes'),
      handBoxes: boxes('handBoxes'),
    );
  }

  /// Pieds (sabots compris) et mains, côté gauche puis droit de l'image :
  /// bottes et gants s'y ajustent.
  final List<Box> feetBoxes;
  final List<Box> handBoxes;

  final double neck;

  /// Bas réel du menton (contour de la mâchoire) : sous cette ligne, une
  /// tenue remplace le corps.
  final double chin;
  final double top;
  final double feet;
  final double centreX;

  /// Largeur du torse (épaules aux hanches, bras compris).
  final double torso;
}

/// Corps de base : repères, gabarit des tenues, crâne, main, peau.
class BodyMeta {
  const BodyMeta({
    required this.frame,
    required this.gabarit,
    required this.head,
    required this.handX,
    required this.handY,
    required this.skinRef,
  });

  factory BodyMeta.fromJson(Map<String, dynamic> json) {
    final hand = json['hand'] as List<dynamic>;
    final ref = json['skinRef'] as List<dynamic>;
    return BodyMeta(
      frame: BodyFrame.fromJson(json),
      gabarit: json['gabarit'] as String,
      head: HeadFrame.fromJson(json),
      handX: (hand[0] as num).toDouble(),
      handY: (hand[1] as num).toDouble(),
      skinRef: luminanceOf(
        (ref[0] as num).toInt(),
        (ref[1] as num).toInt(),
        (ref[2] as num).toInt(),
      ),
    );
  }

  final BodyFrame frame;
  final String gabarit;
  final HeadFrame head;
  Skull get skull => head.skull;
  final double handX;
  final double handY;

  /// Luminance de la peau dessinée (référence de la recoloration).
  final double skinRef;
}

/// Gabarit de tenue : repères, main (prise de l'arme) et peau dessinée.
class OutfitTemplate {
  const OutfitTemplate({
    required this.frame,
    required this.handX,
    required this.handY,
    required this.skinRef,
  });

  factory OutfitTemplate.fromJson(Map<String, dynamic> json) {
    final hand = json['hand'] as List<dynamic>;
    final ref = json['skinRef'] as List<dynamic>;
    return OutfitTemplate(
      frame: BodyFrame.fromJson(json),
      handX: (hand[0] as num).toDouble(),
      handY: (hand[1] as num).toDouble(),
      skinRef: luminanceOf(
        (ref[0] as num).toInt(),
        (ref[1] as num).toInt(),
        (ref[2] as num).toInt(),
      ),
    );
  }

  final BodyFrame frame;
  final double handX;
  final double handY;

  /// Luminance de la peau nue du gabarit (cou, mains), recolorée à la
  /// teinte du personnage.
  final double skinRef;
}

/// Arme : taille du sprite et prise de la main (fraction de la hauteur).
class WeaponMeta {
  const WeaponMeta(this.width, this.height, this.grip);

  factory WeaponMeta.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as List<dynamic>;
    return WeaponMeta(
      (size[0] as num).toInt(),
      (size[1] as num).toInt(),
      (json['grip'] as num).toDouble(),
    );
  }

  final int width;
  final int height;
  final double grip;
}

/// Gant peint sur la main du personnage : manchette (fraction de la hauteur
/// du cou aux pieds), doigts couverts ou non, rampes de couleurs du gant (du
/// plus sombre au plus clair) pour la main et la manchette.
class GloveStyle {
  const GloveStyle({
    required this.cuff,
    required this.fingers,
    required this.ramp,
    required this.cuffRamp,
  });

  factory GloveStyle.fromJson(Map<String, dynamic> json) {
    List<(int, int, int)> ramp(String key) => [
      for (final c in json[key] as List<dynamic>? ?? const [])
        (
          ((c as List<dynamic>)[0] as num).toInt(),
          (c[1] as num).toInt(),
          (c[2] as num).toInt(),
        ),
    ];
    return GloveStyle(
      cuff: (json['cuff'] as num).toDouble(),
      fingers: json['fingers'] as bool,
      ramp: ramp('ramp'),
      cuffRamp: ramp('cuffRamp'),
    );
  }

  final double cuff;
  final bool fingers;
  final List<(int, int, int)> ramp;
  final List<(int, int, int)> cuffRamp;
}

/// Repères de tous les sprites (`assets/sprites/sprites.json`, produit par
/// `tool/sprites/build.py`).
class SpriteMeta {
  const SpriteMeta({
    required this.width,
    required this.height,
    required this.skinAlpha,
    required this.frontAlpha,
    required this.bodies,
    required this.templates,
    required this.hairSources,
    required this.weapons,
    this.raceBeards = const {},
    this.pieceSlots = const {},
    this.gloves = const {},
  });

  factory SpriteMeta.fromJson(Map<String, dynamic> json) {
    final canvas = json['canvas'] as List<dynamic>;
    Map<String, T> map<T>(String key, T Function(dynamic) f) => {
      for (final e in (json[key] as Map<String, dynamic>).entries)
        e.key: f(e.value),
    };
    return SpriteMeta(
      width: (canvas[0] as num).toInt(),
      height: (canvas[1] as num).toInt(),
      skinAlpha: (json['skinAlpha'] as num).toInt(),
      frontAlpha: (json['frontAlpha'] as num).toInt(),
      bodies: map(
        'bodies',
        (v) => BodyMeta.fromJson(v as Map<String, dynamic>),
      ),
      templates: map(
        'templates',
        (v) => OutfitTemplate.fromJson(v as Map<String, dynamic>),
      ),
      hairSources: map(
        'hairSources',
        (v) => HeadFrame.fromJson(v as Map<String, dynamic>),
      ),
      weapons: map(
        'weapons',
        (v) => WeaponMeta.fromJson(v as Map<String, dynamic>),
      ),
      raceBeards: {
        for (final r in json['raceBeards'] as List<dynamic>? ?? const [])
          r as String,
      },
      pieceSlots: {
        for (final e
            in (json['pieces'] as Map<String, dynamic>? ?? const {}).entries)
          e.key: e.value as String,
      },
      gloves: {
        for (final e
            in (json['gloves'] as Map<String, dynamic>? ?? const {}).entries)
          e.key: GloveStyle.fromJson(e.value as Map<String, dynamic>),
      },
    );
  }

  final int width;
  final int height;

  /// Alpha qui marque la peau des corps et la peau nue des tenues.
  final int skinAlpha;

  /// Alpha des pixels d'un corps dessinés devant la coiffure (cornes).
  final int frontAlpha;
  final Map<String, BodyMeta> bodies;
  final Map<String, OutfitTemplate> templates;
  final Map<String, HeadFrame> hairSources;
  final Map<String, WeaponMeta> weapons;

  /// Races dont les barbes sont dessinées sur leur propre visage
  /// (`beards/<race>/bNN.png`, corps masculin) : posées telles quelles.
  final Set<String> raceBeards;

  /// Emplacement de chaque pièce séparée (`top`, `legs`, `feet`, `hands`).
  final Map<String, String> pieceSlots;

  /// Gants peints sur la main du personnage (au lieu d'un calque posé).
  final Map<String, GloveStyle> gloves;

  /// Barbe dessinée sur ce corps même, plutôt qu'adaptée depuis l'humain ?
  bool ownBeard(String bodyId) {
    final i = bodyId.lastIndexOf('_');
    if (i < 0 || bodyId.substring(i + 1) != 'male') return false;
    return raceBeards.contains(bodyId.substring(0, i));
  }
}

/// Déformation d'un calque de tête : ligne source et échelle horizontale de
/// chaque ligne de la toile, centres du crâne cible et source.
class HeadWarp {
  const HeadWarp(this.rows, this.scales, this.targetCentre, this.sourceCentre);

  final List<double> rows;
  final List<double> scales;
  final double targetCentre;
  final double sourceCentre;
}

/// Calques chargés pour une apparence (chemins : [SpriteComposer.paths]).
class SpriteLayers {
  const SpriteLayers({
    required this.body,
    this.outfit,
    this.hair,
    this.beard,
    this.weapon,
    this.pieces = const [],
  });

  final RgbaImage body;
  final RgbaImage? outfit;

  /// Pièces séparées, dans l'ordre de [CharacterAppearance.pieces].
  final List<RgbaImage> pieces;
  final RgbaImage? hair;
  final RgbaImage? beard;
  final RgbaImage? weapon;
}

/// Longueur de chaque famille d'armes, en fraction de la hauteur du corps.
const Map<String, double> weaponLength = {
  'sword': 0.5,
  'dagger': 0.28,
  'scimitar': 0.46,
  'axe': 0.5,
  'mace': 0.42,
  'hammer': 0.48,
  'staff': 0.8,
  'halberd': 0.9,
  'bow': 0.62,
  'rifle': 0.6,
  'spear': 0.9,
  'wand': 0.24,
  'scythe': 0.88,
};

/// Hauteur de la bande du cou gardée sous le menton avec une tenue, en
/// fraction de la hauteur du menton aux pieds.
const double neckBandRatio = 0.08;

/// Écart maximal comblé entre le cou et le haut d'une tenue, en fraction de
/// la hauteur du menton aux pieds.
const double neckGapRatio = 0.05;

/// Armes courtes tenues au repos, lame (ou tête) vers le bas ; les armes
/// d'hast, bâtons, arcs et mousquet restent debout.
const Set<String> loweredWeapons = {
  'sword',
  'dagger',
  'scimitar',
  'axe',
  'mace',
  'hammer',
  'wand',
};

/// Demi-axes de la main qui passe devant la poignée d'une arme, en fraction
/// de la hauteur du corps.
const double handRadiusX = 0.026;
const double handRadiusY = 0.036;

/// Hauteur du pommeau d'une arme au repos au-dessus du centre du poing, en
/// fraction de la hauteur du corps.
const double pommelAbove = 0.035;

/// Gants peints : part de la main couverte par une mitaine, demi-largeur de
/// la fenêtre autour de la paume et marge des bouts des doigts (fractions
/// de la hauteur du cou aux pieds), luminance du contour sombre, anneaux de
/// bord repris et écart de chromaticité toléré avec la peau.
const double gloveFingerless = 0.55;
const double gloveHalf = 0.06;
const double gloveTips = 0.02;
const double gloveOutline = 0.22;
const int gloveEdge = 2;
const double gloveChroma = 0.06;

/// Sous cette luminance relative (creux entre les doigts), la main garde la
/// rampe sombre plutôt que l'image du gant.
const double gloveCrease = 0.12;

/// Bornes de l'échelle d'une botte ou d'un gant ajusté au corps.
const double extremityMinScale = 0.8;
const double extremityMaxScale = 1.8;

/// Échelle d'une botte (couvre la boîte du pied : le plus grand des deux
/// rapports) ou d'un gant (longueur de la main, plus stable que sa largeur
/// qui dépend de la pose), bornée ; `null` si une boîte est vide. Même
/// calcul que `tool/sprites/preview.py`.
double? extremityScale(Box from, Box to, {required bool feet}) {
  if (math.min(
        math.min(from.width, from.height),
        math.min(to.width, to.height),
      ) <=
      0) {
    return null;
  }
  final k = feet
      ? math.max(to.width / from.width, to.height / from.height)
      : to.height / from.height;
  return k.clamp(extremityMinScale, extremityMaxScale);
}

/// Part centrale du visage (en demi-largeur de tête) où aucune mèche n'est
/// dessinée.
const double faceInner = 0.6;

/// Marge (pixels) de la barbe au-delà du contour de la joue, au-dessus du
/// menton.
const double jawMargin = 0.5;

/// Part de la teinture dans la couleur d'une tenue teinte.
const double dyeStrength = 0.6;

double luminanceOf(int r, int g, int b) => 0.299 * r + 0.587 * g + 0.114 * b;

/// Recoloration par carte de dégradé : la luminance du pixel (rapportée à
/// [reference]) garde le modelé, [color] donne la teinte. Même formule que
/// `tool/sprites/preview.py`.
(int, int, int) tintPixel(int r, int g, int b, double reference, int color) {
  final k = (luminanceOf(r, g, b) / math.max(reference, 1)).clamp(0.0, 2.2);
  int channel(int c) {
    final v = k <= 1 ? c * k : c + (255 - c) * (k - 1) * 0.55;
    return v.round().clamp(0, 255);
  }

  return (
    channel((color >> 16) & 0xFF),
    channel((color >> 8) & 0xFF),
    channel(color & 0xFF),
  );
}

/// Teinte douce des cheveux et barbes : reflets et ombres resserrés, pour
/// que les reflets clairs du modèle magenta ne virent pas au blanc. Même
/// formule que `tint_hair` dans `tool/sprites/preview.py`.
(int, int, int) tintHairPixel(
  int r,
  int g,
  int b,
  double reference,
  int color,
) {
  final k = (luminanceOf(r, g, b) / math.max(reference, 1)).clamp(0.3, 1.6);
  // Reflets : la couleur s'éclaircit dans sa propre teinte ; le blanc ajouté
  // est dosé selon sa clarté (une barbe noire ne vire pas au gris plat).
  final lift =
      0.35 *
      (luminanceOf((color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF) /
              140)
          .clamp(0.3, 1.0);
  int channel(int c) {
    if (k <= 1) return (c * k).round().clamp(0, 255);
    final base = math.min(255, c * math.min(k, 1.3));
    return (base + (255 - base) * (k - 1) * lift).round().clamp(0, 255);
  }

  return (
    channel((color >> 16) & 0xFF),
    channel((color >> 8) & 0xFF),
    channel(color & 0xFF),
  );
}

/// Assemble le personnage en pixel art : corps (peau recolorée), tenue
/// adaptée au gabarit, barbe, coiffure posée sur le crâne, arme en main.
class SpriteComposer {
  const SpriteComposer(this.meta);

  final SpriteMeta meta;

  /// Fichiers (sous `assets/sprites/`) nécessaires à une apparence.
  ({
    String body,
    String? outfit,
    String? hair,
    String? beard,
    String? weapon,
    List<String> pieces,
  })
  paths(CharacterAppearance a) {
    final body = meta.bodies[a.bodyId];
    return (
      pieces: body == null
          ? const <String>[]
          : [
              for (final p in a.pieces)
                'pieces/${p.spriteId}_${body.gabarit}.png',
            ],
      body: 'bodies/${a.bodyId}.png',
      outfit: a.outfitId == null || body == null
          ? null
          : 'outfits/${a.outfitId}_${body.gabarit}.png',
      hair: a.hairId == null ? null : 'hair/${a.hairId}.png',
      beard: switch (a.beardId) {
        null => null,
        final id when meta.ownBeard(a.bodyId) =>
          'beards/${a.bodyId.substring(0, a.bodyId.lastIndexOf('_'))}/$id.png',
        final id => 'beards/$id.png',
      },
      weapon: a.weaponId == null || !meta.weapons.containsKey(a.weaponId)
          ? null
          : 'weapons/${a.weaponId}.png',
    );
  }

  RgbaImage compose(CharacterAppearance a, SpriteLayers layers) {
    final body = meta.bodies[a.bodyId]!;
    final out = RgbaImage(meta.width, meta.height);
    // Peau visible de la toile (1) : les gants y sont peints.
    final marks = Uint8List(meta.width * meta.height);
    final src = layers.body;
    final neck = body.frame.chin.round();
    final outfit = layers.outfit;
    // Bande du cou sous le menton : avec une tenue, le vrai cou du personnage
    // y reste (pas de marche entre son cou et celui du modèle de la tenue).
    final neckBand =
        neck + (neckBandRatio * (body.frame.feet - body.frame.neck)).round();
    bool ownNeck(int x, int y) =>
        y <= neckBand &&
        x >= 0 &&
        x < src.width &&
        y >= 0 &&
        y < src.height &&
        src.pixels[(y * src.width + x) * 4 + 3] == meta.skinAlpha;
    // Corps : peau recolorée ; avec une tenue, seules la tête et la peau du
    // cou restent (la tenue remplace le reste du corps, peau nue comprise).
    for (var y = 0; y < src.height; y++) {
      if (outfit != null && y > neckBand) break;
      for (var x = 0; x < src.width; x++) {
        final i = (y * src.width + x) * 4;
        final alpha = src.pixels[i + 3];
        if (alpha == 0) continue;
        if (outfit != null && y > neck && alpha != meta.skinAlpha) continue;
        var r = src.pixels[i];
        var g = src.pixels[i + 1];
        var b = src.pixels[i + 2];
        if (alpha == meta.skinAlpha) {
          (r, g, b) = tintPixel(r, g, b, body.skinRef, a.skinColor);
        }
        _put(out, x, y, r, g, b);
        marks[y * out.width + x] = alpha == meta.skinAlpha ? 1 : 0;
      }
    }
    var handX = body.handX;
    var handY = body.handY;
    if (outfit != null) {
      final template = meta.templates[body.gabarit]!;
      final t = template.frame;
      final f = body.frame;
      final sy = (f.feet - f.neck) / (t.feet - t.neck);
      final sx = f.torso / t.torso;
      final originY = f.feet - t.feet * sy;
      final tint = a.outfitTint;
      final ref = tint == null ? 0.0 : _medianLuminance(outfit);
      _place(
        out,
        outfit,
        scaleX: sx,
        scaleY: sy,
        originX: f.centreX - t.centreX * sx,
        originY: originY,
        // Peau du cou de la tenue : celle du personnage la remplace.
        skip: (x, y, alpha) => alpha == meta.skinAlpha && ownNeck(x, y),
        marks: marks,
        skinAlpha: meta.skinAlpha,
        colour: (r, g, b, alpha) {
          // Peau nue de la tenue (cou, mains) : teinte du personnage.
          if (alpha == meta.skinAlpha) {
            return tintPixel(r, g, b, template.skinRef, a.skinColor);
          }
          if (tint == null) return (r, g, b);
          final (tr, tg, tb) = tintPixel(r, g, b, ref, tint);
          int mix(int o, int d) =>
              (o + (d - o) * dyeStrength).round().clamp(0, 255);
          return (mix(r, tr), mix(g, tg), mix(b, tb));
        },
      );
      _fillNeckGap(
        out,
        marks,
        neck,
        (neckGapRatio * (f.feet - f.neck)).round(),
      );
      // L'arme suit la main de la tenue.
      handX = f.centreX + (template.handX - t.centreX) * sx;
      handY = originY + template.handY * sy;
    }
    // Pièces séparées : même cadrage que les tenues (gabarit du corps) ; leur
    // peau nue prend la teinte du personnage.
    if (layers.pieces.isNotEmpty) {
      final template = meta.templates[body.gabarit]!;
      final t = template.frame;
      final f = body.frame;
      final sy = (f.feet - f.neck) / (t.feet - t.neck);
      final sx = f.torso / t.torso;
      for (var k = 0; k < layers.pieces.length && k < a.pieces.length; k++) {
        // Gant peint plus bas sur la main elle-même.
        if (meta.gloves.containsKey(a.pieces[k].spriteId)) continue;
        final layer = layers.pieces[k];
        final tint = a.pieces[k].tint;
        final ref = tint == null ? 0.0 : _medianLuminance(layer);
        (int, int, int) colour(int r, int g, int b, int alpha) {
          if (alpha == meta.skinAlpha) {
            return tintPixel(r, g, b, template.skinRef, a.skinColor);
          }
          if (tint == null) return (r, g, b);
          final (tr, tg, tb) = tintPixel(r, g, b, ref, tint);
          int mix(int o, int d) =>
              (o + (d - o) * dyeStrength).round().clamp(0, 255);
          return (mix(r, tr), mix(g, tg), mix(b, tb));
        }

        final slot = meta.pieceSlots[a.pieces[k].spriteId];
        final cut = (t.centreX + 0.5).floor();
        // Bottes et gants sans tenue : ajustés au pied et à la main de ce
        // corps (sabots, grandes mains), chaque côté à l'échelle de sa boîte.
        final feet = slot == 'feet';
        final from = feet ? t.feetBoxes : t.handBoxes;
        final to = feet ? f.feetBoxes : f.handBoxes;
        final fitted =
            outfit == null &&
            (feet || slot == 'hands') &&
            from.length == 2 &&
            to.length == 2;
        if (fitted) {
          for (var side = 0; side < 2; side++) {
            final k = extremityScale(from[side], to[side], feet: feet);
            if (k == null) continue;
            final src = from[side];
            final dst = to[side];
            _place(
              out,
              _half(layer, cut, left: side == 0),
              scaleX: k,
              scaleY: k,
              originX: dst.centreX - src.centreX * k,
              originY: feet
                  ? dst.bottom - src.bottom * k
                  : dst.centreY - src.centreY * k,
              colour: colour,
              marks: marks,
              skinAlpha: meta.skinAlpha,
            );
          }
          continue;
        }
        if (slot != 'hands') {
          _place(
            out,
            layer,
            scaleX: sx,
            scaleY: sy,
            originX: f.centreX - t.centreX * sx,
            originY: f.feet - t.feet * sy,
            colour: colour,
            marks: marks,
            skinAlpha: meta.skinAlpha,
          );
          continue;
        }
        // Gants sur une tenue : chaque gant calé sur la main de la tenue.
        final templateHands = [template.handX, 2 * t.centreX - template.handX]
          ..sort();
        final bodyHands = [handX, 2 * f.centreX - handX]..sort();
        for (final left in [true, false]) {
          final templateHand = templateHands[left ? 0 : 1];
          final bodyHand = bodyHands[left ? 0 : 1];
          _place(
            out,
            _half(layer, cut, left: left),
            scaleX: sx,
            scaleY: sy,
            originX: bodyHand - templateHand * sx,
            originY: handY - template.handY * sy,
            colour: colour,
            marks: marks,
            skinAlpha: meta.skinAlpha,
          );
        }
      }
    }
    // Gants : peints sur la main visible du personnage (sa forme exacte),
    // aux couleurs du gant.
    for (var k = 0; k < a.pieces.length; k++) {
      final style = meta.gloves[a.pieces[k].spriteId];
      if (style == null) continue;
      _paintGlove(
        out,
        marks,
        body,
        meta.templates[body.gabarit]!,
        style,
        outfit: outfit != null,
        skinColor: a.skinColor,
        layer: k < layers.pieces.length ? layers.pieces[k] : null,
      );
    }
    // Visage intact : le col d'une tenue ou d'un haut ne recouvre jamais la
    // peau du visage au-dessus du menton.
    if (outfit != null || layers.pieces.isNotEmpty) {
      for (var y = 0; y <= neck && y < src.height; y++) {
        for (var x = 0; x < src.width; x++) {
          final i = (y * src.width + x) * 4;
          if (src.pixels[i + 3] != meta.skinAlpha) continue;
          final (r, g, b) = tintPixel(
            src.pixels[i],
            src.pixels[i + 1],
            src.pixels[i + 2],
            body.skinRef,
            a.skinColor,
          );
          _put(out, x, y, r, g, b);
        }
      }
    }
    final beard = layers.beard;
    // Barbe dessinée sur ce visage : posée telle quelle (pose identité).
    final beardSource = meta.ownBeard(a.bodyId)
        ? body.head
        : meta.hairSources['beard'];
    if (beard != null && beardSource != null) {
      final ref = _medianLuminance(beard);
      final color = a.beardColor ?? a.hairColor;
      _warp(
        out,
        beard,
        headWarp(beardSource, body.head, meta.height, hugJaw: true),
        (r, g, b) => tintHairPixel(r, g, b, ref, color),
        // Au-dessus du menton, la barbe suit le contour du visage : rien
        // au-delà de la joue.
        skip: (x, y) {
          if (y > body.head.neck) return false;
          final half = body.head.halfWidthAt(y.toDouble());
          return half != null &&
              (x + 0.5 - body.head.skull.centre).abs() > half + jawMargin;
        },
      );
    }
    final hair = layers.hair;
    final hairSource = a.hairId == null
        ? null
        : meta.hairSources[a.hairId!.startsWith('m') ? 'male' : 'female'];
    if (hair != null && hairSource != null) {
      final ref = _medianLuminance(hair);
      final brow = body.head.brow;
      _warp(
        out,
        hair,
        headWarp(hairSource, body.head, meta.height),
        (r, g, b) => tintHairPixel(r, g, b, ref, a.hairColor),
        // Visage dégagé : pas de mèche sur le centre du visage (yeux, nez,
        // bouche) entre sourcils et menton ; les mèches qui tombent sur les
        // joues restent entières.
        skip: (x, y) {
          if (y < brow + 1 || y > body.frame.neck) return false;
          if (src.alphaAt(x, y) != meta.skinAlpha) return false;
          final half = body.head.halfWidthAt(y.toDouble());
          return half != null &&
              (x + 0.5 - body.head.skull.centre).abs() < faceInner * half;
        },
      );
    }
    // Cornes devant la coiffure.
    for (var y = 0; y <= neck && y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        final i = (y * src.width + x) * 4;
        if (src.pixels[i + 3] != meta.frontAlpha) continue;
        _put(out, x, y, src.pixels[i], src.pixels[i + 1], src.pixels[i + 2]);
      }
    }
    final weapon = layers.weapon;
    final w = a.weaponId == null ? null : meta.weapons[a.weaponId];
    if (weapon != null && w != null) {
      final kind = a.weaponId!.split('_').first;
      final length =
          (weaponLength[kind] ?? 0.5) * (body.frame.feet - body.frame.top);
      final s = length / w.height;
      // La main passe devant la poignée : l'arme est tenue, pas collée.
      final size = body.frame.feet - body.frame.top;
      final rx = handRadiusX * size;
      final ry = handRadiusY * size;
      final hand = <(int, int, int, int, int)>[
        for (var y = (handY - ry).floor(); y <= (handY + ry).ceil(); y++)
          for (var x = (handX - rx).floor(); x <= (handX + rx).ceil(); x++)
            if (x >= 0 &&
                y >= 0 &&
                x < out.width &&
                y < out.height &&
                math.pow((x + 0.5 - handX) / rx, 2) +
                        math.pow((y + 0.5 - handY) / ry, 2) <=
                    1 &&
                out.pixels[(y * out.width + x) * 4 + 3] != 0)
              (
                x,
                y,
                out.pixels[(y * out.width + x) * 4],
                out.pixels[(y * out.width + x) * 4 + 1],
                out.pixels[(y * out.width + x) * 4 + 2],
              ),
      ];
      // Arme courte au repos : retournée, la poignée reste dans la main.
      final lowered = loweredWeapons.contains(kind);
      _place(
        out,
        lowered ? _flipped(weapon) : weapon,
        scaleX: s,
        scaleY: s,
        originX: handX - w.width * s / 2,
        // Au repos, le pommeau dépasse juste au-dessus du poing ; debout,
        // la poignée de l'arme est dans la main.
        originY: lowered
            ? handY - pommelAbove * size
            : handY - w.grip * w.height * s,
      );
      for (final (x, y, r, g, b) in hand) {
        _put(out, x, y, r, g, b);
      }
    }
    return out;
  }

  /// Pose d'un calque de tête dessiné sur [source] sur la tête [target] :
  /// pour chaque ligne de la toile, ligne source et échelle horizontale.
  /// Verticalement, sommet → sourcils → menton de la source sur ceux de la
  /// cible ; horizontalement, la demi-largeur de la tête à chaque ligne (la
  /// coiffure épouse le crâne au-dessus des sourcils, la barbe la mâchoire
  /// avec [hugJaw]). Même calcul que `tool/sprites/preview.py`.
  static HeadWarp headWarp(
    HeadFrame source,
    HeadFrame target,
    int height, {
    bool hugJaw = false,
  }) {
    final ss = source.skull;
    final ds = target.skull;
    final s = ds.width / ss.width;
    final sb = source.brow;
    final sn = source.neck;
    final db = target.brow;
    final dn = target.neck;
    final sy1 = ((db - ds.top) / (sb - ss.top)).clamp(0.6 * s, 1.4 * s);
    final sy2 = ((dn - db) / (sn - sb)).clamp(0.6 * s, 1.4 * s);
    final chin = db + (sn - sb) * sy2;
    final rows = List<double>.generate(height, (y) {
      final yc = y + 0.5;
      if (yc < db) return sb - (db - yc) / sy1;
      if (yc < chin) return sb + (yc - db) / sy2;
      return sn + (yc - chin) / s;
    });
    final scales = List<double?>.generate(height, (y) {
      final yc = y + 0.5;
      // Barbe : sous le menton, l'échelle du crâne. Coiffure : sous les
      // sourcils, la largeur du front continue (pas de marche aux joues).
      if (hugJaw && yc >= chin) return s;
      if (!hugJaw && yc >= db) return null;
      if (hugJaw && yc < db) return null;
      final wd = target.halfWidthAt(y.toDouble());
      final ws = source.halfWidthAt(rows[y]);
      if (wd == null || ws == null) return null;
      return (wd / ws).clamp(0.75 * s, 1.35 * s);
    });
    if (hugJaw) {
      // Barbe : une seule échelle (moyenne sur la mâchoire), pour garder sa
      // forme sur une mâchoire très différente (menton pointu, bajoues).
      final jaw = [
        for (var y = 0; y < height; y++)
          if (scales[y] case final k? when y + 0.5 >= db && y + 0.5 < chin) k,
      ];
      final k = jaw.isEmpty ? s : jaw.reduce((a, b) => a + b) / jaw.length;
      // Même échelle à la verticale, calée sur le menton du corps : pas
      // d'étirement.
      final beardRows = List<double>.generate(
        height,
        (y) => sn + (y + 0.5 - dn) / k,
      );
      return HeadWarp(beardRows, List.filled(height, k), ds.centre, ss.centre);
    }
    // Lignes sans mesure (au-dessus du crâne) : échelle de la ligne mesurée
    // la plus proche.
    final known = [
      for (var y = 0; y < height; y++)
        if (scales[y] != null && rows[y] >= 0) y,
    ];
    final filled = List<double>.generate(height, (y) {
      final k = scales[y];
      if (k != null) return k;
      if (known.isEmpty) return s;
      var best = known.first;
      for (final i in known) {
        if ((i - y).abs() < (best - y).abs()) best = i;
      }
      return scales[best]!;
    });
    return HeadWarp(rows, filled, ds.centre, ss.centre);
  }

  static void _warp(
    RgbaImage out,
    RgbaImage layer,
    HeadWarp warp,
    (int, int, int) Function(int r, int g, int b) colour, {
    bool Function(int x, int y)? skip,
  }) {
    for (var y = 0; y < out.height; y++) {
      final r = warp.rows[y].floor();
      if (r < 0 || r >= layer.height) continue;
      final k = warp.scales[y];
      for (var x = 0; x < out.width; x++) {
        final c = (warp.sourceCentre + (x + 0.5 - warp.targetCentre) / k)
            .floor();
        if (c < 0 || c >= layer.width) continue;
        final i = (r * layer.width + c) * 4;
        if (layer.pixels[i + 3] == 0) continue;
        if (skip != null && skip(x, y)) continue;
        final (cr, cg, cb) = colour(
          layer.pixels[i],
          layer.pixels[i + 1],
          layer.pixels[i + 2],
        );
        _put(out, x, y, cr, cg, cb);
      }
    }
  }

  /// Raccord entre le cou et le haut de la tenue : dans chaque colonne, la
  /// fente vide sous la peau du cou prend la couleur du premier
  /// pixel de tenue en dessous, si elle ne dépasse pas [gap] pixels. Sans ça,
  /// un trait vide barre la gorge des races au cou épais (minotaure).
  static void _fillNeckGap(RgbaImage img, Uint8List marks, int neck, int gap) {
    final g = gap < 1 ? 1 : gap;
    final y0 = neck - g < 1 ? 1 : neck - g;
    final y1 = neck + g + 1 < img.height ? neck + g + 1 : img.height;
    for (var x = 0; x < img.width; x++) {
      for (var y = y0; y < y1; y++) {
        if (img.alphaAt(x, y) != 0 || marks[(y - 1) * img.width + x] != 1) {
          continue;
        }
        var end = y;
        while (end < img.height && end - y <= g && img.alphaAt(x, end) == 0) {
          end++;
        }
        if (end < img.height && end - y <= g) {
          final from = (end * img.width + x) * 4;
          for (var k = y; k < end; k++) {
            final to = (k * img.width + x) * 4;
            img.pixels.setRange(to, to + 4, img.pixels, from);
            marks[k * img.width + x] = marks[end * img.width + x];
          }
        }
        break;
      }
    }
  }

  static void _put(RgbaImage img, int x, int y, int r, int g, int b) {
    if (x < 0 || y < 0 || x >= img.width || y >= img.height) return;
    final i = (y * img.width + x) * 4;
    img.pixels
      ..[i] = r
      ..[i + 1] = g
      ..[i + 2] = b
      ..[i + 3] = 255;
  }

  /// Pose [layer] mis à l'échelle au plus proche voisin, origine en
  /// (originX, originY) ; [colour] recolore chaque pixel.
  static void _place(
    RgbaImage out,
    RgbaImage layer, {
    required double scaleX,
    required double scaleY,
    required double originX,
    required double originY,
    (int, int, int) Function(int r, int g, int b, int alpha)? colour,
    bool Function(int x, int y, int alpha)? skip,
    Uint8List? marks,
    int skinAlpha = -1,
  }) {
    final nw = math.max(1, (layer.width * scaleX).round());
    final nh = math.max(1, (layer.height * scaleY).round());
    final ox = originX.round();
    final oy = originY.round();
    for (var j = 0; j < nh; j++) {
      final y = oy + j;
      if (y < 0 || y >= out.height) continue;
      final sy = math.min(layer.height - 1, (j / scaleY).floor());
      for (var i = 0; i < nw; i++) {
        final x = ox + i;
        if (x < 0 || x >= out.width) continue;
        final sx = math.min(layer.width - 1, (i / scaleX).floor());
        final k = (sy * layer.width + sx) * 4;
        final alpha = layer.pixels[k + 3];
        if (alpha == 0) continue;
        if (skip != null && skip(x, y, alpha)) continue;
        var r = layer.pixels[k];
        var g = layer.pixels[k + 1];
        var b = layer.pixels[k + 2];
        if (colour != null) (r, g, b) = colour(r, g, b, alpha);
        _put(out, x, y, r, g, b);
        if (marks != null) {
          marks[y * out.width + x] = alpha == skinAlpha ? 1 : 0;
        }
      }
    }
  }

  /// Gant peint sur la main visible (peau de la toile, [marks]) : la forme
  /// est celle de la main du personnage, les couleurs celles du gant (rampe
  /// choisie par la luminance de la peau, manchette au-dessus du poignet).
  /// Même calcul que `paint_glove` de `tool/sprites/preview.py`.
  static void _paintGlove(
    RgbaImage out,
    Uint8List marks,
    BodyMeta body,
    OutfitTemplate template,
    GloveStyle style, {
    required bool outfit,
    required int skinColor,
    RgbaImage? layer,
  }) {
    if (style.ramp.isEmpty) return;
    final f = body.frame;
    final t = template.frame;
    final span = f.feet - f.neck;
    final sy = span / (t.feet - t.neck);
    final sx = f.torso / t.torso;
    final ox = f.centreX - t.centreX * sx;
    final oy = f.feet - t.feet * sy;
    final boxes = outfit
        ? [
            for (final b in t.handBoxes)
              Box(
                ox + b.left * sx,
                oy + b.top * sy,
                ox + b.right * sx,
                oy + b.bottom * sy,
              ),
          ]
        : f.handBoxes;
    final palm = outfit
        ? f.centreX + (template.handX - t.centreX) * sx
        : body.handX;
    final palms = [palm, 2 * f.centreX - palm]..sort();
    final w = out.width;
    final h = out.height;
    final px = out.pixels;
    double lumAt(int i) => luminanceOf(px[i * 4], px[i * 4 + 1], px[i * 4 + 2]);
    final sr = (skinColor >> 16) & 0xFF;
    final sg = (skinColor >> 8) & 0xFF;
    final sb = skinColor & 0xFF;
    final sTot = math.max(1, sr + sg + sb);
    for (var side = 0; side < boxes.length && side < 2; side++) {
      final box = boxes[side];
      if (box.width <= 0 || box.height <= 0) continue;
      final centre = palms[side];
      final top = box.top - style.cuff * span;
      final bottom = style.fingers
          ? box.bottom + gloveTips * span
          : box.top + gloveFingerless * box.height;
      final halfW = gloveHalf * span;
      final y0 = math.max(0, top.floor());
      final y1 = math.min(h, bottom.ceil());
      bool inWindow(int x, int y) =>
          y >= y0 && y < y1 && (x + 0.5 - centre).abs() <= halfW;
      bool candidate(int x, int y) =>
          inWindow(x, y) &&
          marks[y * w + x] == 1 &&
          px[(y * w + x) * 4 + 3] > 0;
      // Peau reliée à la main (8 voisins) depuis la main elle-même.
      final region = Uint8List(w * h);
      final stack = <int>[];
      for (var y = y0; y < y1; y++) {
        if (y < box.top || y >= box.bottom) continue;
        for (var x = 0; x < w; x++) {
          if (candidate(x, y)) {
            region[y * w + x] = 1;
            stack.add(y * w + x);
          }
        }
      }
      while (stack.isNotEmpty) {
        final i = stack.removeLast();
        final x = i % w;
        final y = i ~/ w;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
            final j = ny * w + nx;
            if (region[j] == 1 || !candidate(nx, ny)) continue;
            region[j] = 1;
            stack.add(j);
          }
        }
      }
      // Bords de la main (bouts des doigts, reflets) proches de la couleur
      // de la peau, hors contour sombre.
      bool edgeOk(int x, int y) {
        if (!inWindow(x, y)) return false;
        final i = y * w + x;
        if (px[i * 4 + 3] == 0 || lumAt(i) / 255 <= gloveOutline) return false;
        final r = px[i * 4];
        final g = px[i * 4 + 1];
        final b = px[i * 4 + 2];
        final tot = math.max(1, r + g + b);
        final chroma =
            (r / tot - sr / sTot).abs() + (g / tot - sg / sTot).abs();
        return chroma < gloveChroma;
      }

      for (var pass = 0; pass < gloveEdge; pass++) {
        final add = <int>[];
        for (var i = 0; i < w * h; i++) {
          if (region[i] == 1) continue;
          final x = i % w;
          final y = i ~/ w;
          final touches =
              (y > 0 && region[i - w] == 1) ||
              (y < h - 1 && region[i + w] == 1) ||
              (x > 0 && region[i - 1] == 1) ||
              (x < w - 1 && region[i + 1] == 1);
          if (touches && edgeOk(x, y)) add.add(i);
        }
        for (final i in add) {
          region[i] = 1;
        }
      }
      // Luminance de la main avant peinture (modelé et creux des doigts).
      final before = Float64List(w * h);
      for (var i = 0; i < w * h; i++) {
        if (region[i] == 1) before[i] = lumAt(i);
      }
      final lums = <double>[
        for (var i = 0; i < w * h; i++)
          if (region[i] == 1) before[i],
      ];
      if (lums.isEmpty) continue;
      final lo = _percentile(lums, 0.05);
      final hi = _percentile(lums, 0.95);
      final n = style.ramp.length;
      final cuffRamp = style.cuffRamp.isEmpty ? style.ramp : style.cuffRamp;
      final edgeRows = {top.floor(), if (!style.fingers) bottom.ceil() - 1};
      for (var i = 0; i < w * h; i++) {
        if (region[i] == 0) continue;
        final y = i ~/ w;
        final k = ((before[i] - lo) / math.max(hi - lo, 1e-6)).clamp(0.0, 1.0);
        final idx = math.min((k * n).floor(), n - 1);
        final (r, g, b) = edgeRows.contains(y)
            ? style.ramp[0]
            : y < box.top
            ? cuffRamp[math.min(idx, cuffRamp.length - 1)]
            : style.ramp[idx];
        px
          ..[i * 4] = r
          ..[i * 4 + 1] = g
          ..[i * 4 + 2] = b;
      }
      // Reliefs du gant généré (plaques, coutures, fourrure) : son image,
      // ramenée de la main du gabarit sur celle du personnage, colore
      // l'intérieur de la main ; les creux entre les doigts restent sombres.
      if (layer == null || side >= t.handBoxes.length) continue;
      final src = t.handBoxes[side];
      final k = extremityScale(src, box, feet: false);
      if (k == null) continue;
      for (var i = 0; i < w * h; i++) {
        if (region[i] == 0) continue;
        final shade = ((before[i] - lo) / math.max(hi - lo, 1e-6)).clamp(
          0.0,
          1.0,
        );
        if (shade < gloveCrease) continue;
        final x = i % w;
        final y = i ~/ w;
        // Le liseré du bord, peint après dans l'aperçu, reste.
        if (edgeRows.contains(y)) continue;
        final lx = (src.centreX + (x + 0.5 - box.centreX) / k).floor();
        final ly = (src.centreY + (y + 0.5 - box.centreY) / k).floor();
        if (lx < 0 || ly < 0 || lx >= layer.width || ly >= layer.height) {
          continue;
        }
        final j = (ly * layer.width + lx) * 4;
        if (layer.pixels[j + 3] != 255) continue;
        px
          ..[i * 4] = layer.pixels[j]
          ..[i * 4 + 1] = layer.pixels[j + 1]
          ..[i * 4 + 2] = layer.pixels[j + 2];
      }
    }
  }

  /// Centile [q] (interpolation linéaire, comme numpy).
  static double _percentile(List<double> values, double q) {
    final v = [...values]..sort();
    final pos = (v.length - 1) * q;
    final lo = pos.floor();
    final hi = math.min(lo + 1, v.length - 1);
    return v[lo] + (v[hi] - v[lo]) * (pos - lo);
  }

  /// Moitié gauche (colonnes avant [cut]) ou droite de [layer].
  static RgbaImage _half(RgbaImage layer, int cut, {required bool left}) {
    final out = RgbaImage(layer.width, layer.height);
    final from = left ? 0 : math.max(0, cut);
    final to = left ? math.min(layer.width, cut) : layer.width;
    for (var y = 0; y < layer.height; y++) {
      final row = y * layer.width * 4;
      out.pixels.setRange(
        row + from * 4,
        row + to * 4,
        layer.pixels,
        row + from * 4,
      );
    }
    return out;
  }

  /// [layer] retourné de haut en bas.
  static RgbaImage _flipped(RgbaImage layer) {
    final out = RgbaImage(layer.width, layer.height);
    final row = layer.width * 4;
    for (var y = 0; y < layer.height; y++) {
      out.pixels.setRange(
        y * row,
        (y + 1) * row,
        layer.pixels,
        (layer.height - 1 - y) * row,
      );
    }
    return out;
  }

  static double _medianLuminance(RgbaImage layer) {
    final values = <double>[];
    for (var i = 0; i < layer.pixels.length; i += 4) {
      if (layer.pixels[i + 3] == 0) continue;
      values.add(
        luminanceOf(layer.pixels[i], layer.pixels[i + 1], layer.pixels[i + 2]),
      );
    }
    if (values.isEmpty) return 128;
    values.sort();
    return values[values.length ~/ 2];
  }
}
