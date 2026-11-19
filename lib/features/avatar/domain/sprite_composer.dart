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

/// Repères d'un corps ou d'un gabarit de tenue.
class BodyFrame {
  const BodyFrame({
    required this.neck,
    required this.top,
    required this.feet,
    required this.centreX,
    required this.torso,
  });

  factory BodyFrame.fromJson(Map<String, dynamic> json) => BodyFrame(
    neck: (json['neck'] as num).toDouble(),
    top: (json['top'] as num).toDouble(),
    feet: (json['feet'] as num).toDouble(),
    centreX: (json['cx'] as num).toDouble(),
    torso: (json['torso'] as num).toDouble(),
  );

  final double neck;
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
  });

  final RgbaImage body;
  final RgbaImage? outfit;
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
};

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

/// Assemble le personnage en pixel art : corps (peau recolorée), tenue
/// adaptée au gabarit, barbe, coiffure posée sur le crâne, arme en main.
class SpriteComposer {
  const SpriteComposer(this.meta);

  final SpriteMeta meta;

  /// Fichiers (sous `assets/sprites/`) nécessaires à une apparence.
  ({String body, String? outfit, String? hair, String? beard, String? weapon})
  paths(CharacterAppearance a) {
    final body = meta.bodies[a.bodyId];
    return (
      body: 'bodies/${a.bodyId}.png',
      outfit: a.outfitId == null || body == null
          ? null
          : 'outfits/${a.outfitId}_${body.gabarit}.png',
      hair: a.hairId == null ? null : 'hair/${a.hairId}.png',
      beard: a.beardId == null ? null : 'beards/${a.beardId}.png',
      weapon: a.weaponId == null || !meta.weapons.containsKey(a.weaponId)
          ? null
          : 'weapons/${a.weaponId}.png',
    );
  }

  RgbaImage compose(CharacterAppearance a, SpriteLayers layers) {
    final body = meta.bodies[a.bodyId]!;
    final out = RgbaImage(meta.width, meta.height);
    final src = layers.body;
    final neck = body.frame.neck.round();
    final outfit = layers.outfit;
    // Corps : peau recolorée ; avec une tenue, seule la tête reste (la tenue
    // remplace tout le corps sous le cou, peau nue comprise).
    for (var y = 0; y < src.height; y++) {
      if (outfit != null && y > neck) break;
      for (var x = 0; x < src.width; x++) {
        final i = (y * src.width + x) * 4;
        final alpha = src.pixels[i + 3];
        if (alpha == 0) continue;
        var r = src.pixels[i];
        var g = src.pixels[i + 1];
        var b = src.pixels[i + 2];
        if (alpha == meta.skinAlpha) {
          (r, g, b) = tintPixel(r, g, b, body.skinRef, a.skinColor);
        }
        _put(out, x, y, r, g, b);
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
      // L'arme suit la main de la tenue.
      handX = f.centreX + (template.handX - t.centreX) * sx;
      handY = originY + template.handY * sy;
    }
    final beard = layers.beard;
    final beardSource = meta.hairSources['beard'];
    if (beard != null && beardSource != null) {
      final ref = _medianLuminance(beard);
      final color = a.beardColor ?? a.hairColor;
      _warp(
        out,
        beard,
        headWarp(beardSource, body.head, meta.height, hugJaw: true),
        (r, g, b) => tintPixel(r, g, b, ref, color),
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
        (r, g, b) => tintPixel(r, g, b, ref, a.hairColor),
        // Visage dégagé : pas de mèche sur la peau entre sourcils et menton.
        skip: (x, y) =>
            y >= brow + 1 && y <= neck && src.alphaAt(x, y) == meta.skinAlpha,
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
      _place(
        out,
        weapon,
        scaleX: s,
        scaleY: s,
        originX: handX - w.width * s / 2,
        originY: handY - w.grip * w.height * s,
      );
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
      if (yc >= (hugJaw ? chin : db)) return s;
      if (hugJaw && yc < db) return null;
      final wd = target.halfWidthAt(y.toDouble());
      final ws = source.halfWidthAt(rows[y]);
      if (wd == null || ws == null) return null;
      return (wd / ws).clamp(0.75 * s, 1.35 * s);
    });
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
        var r = layer.pixels[k];
        var g = layer.pixels[k + 1];
        var b = layer.pixels[k + 2];
        if (colour != null) (r, g, b) = colour(r, g, b, alpha);
        _put(out, x, y, r, g, b);
      }
    }
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
