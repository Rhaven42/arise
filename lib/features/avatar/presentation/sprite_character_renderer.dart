import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/domain/character_scene.dart';
import 'package:arise/features/avatar/domain/sprite_composer.dart';
import 'package:arise/features/avatar/presentation/character_renderer.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dossier des sprites du personnage.
const String spritesFolder = 'assets/sprites';

/// Rendu en pixel art : calques SpriteCook assemblés par [SpriteComposer],
/// affichés sans lissage dans un décor selon l'éclairage choisi.
class SpriteCharacterRenderer implements CharacterRenderer {
  const SpriteCharacterRenderer();

  @override
  Widget build({
    required CharacterAppearance appearance,
    CharacterScene scene = const CharacterScene(),
    CharacterSnapshotController? snapshots,
    Key? key,
  }) => _SpriteCharacter(
    appearance: appearance,
    scene: scene,
    snapshots: snapshots,
    key: key,
  );
}

/// Sprites chargés une fois pour toute l'application.
class SpriteAtlas {
  SpriteAtlas._(this.meta);

  static Future<SpriteAtlas>? _instance;

  /// Atlas partagé (chargé au premier appel).
  static Future<SpriteAtlas> load() => _instance ??= () async {
    final json = await rootBundle.loadString('$spritesFolder/sprites.json');
    return SpriteAtlas._(
      SpriteMeta.fromJson(jsonDecode(json) as Map<String, dynamic>),
    );
  }();

  final SpriteMeta meta;
  final Map<String, Future<RgbaImage>> _images = {};

  Future<RgbaImage> image(String path) =>
      _images[path] ??= _decode('$spritesFolder/$path');

  static Future<RgbaImage> _decode(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final bytes = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    final image = RgbaImage(
      frame.image.width,
      frame.image.height,
      bytes!.buffer.asUint8List(),
    );
    frame.image.dispose();
    codec.dispose();
    return image;
  }

  /// Personnage assemblé, prêt à peindre.
  Future<ui.Image> render(CharacterAppearance appearance) async {
    final composer = SpriteComposer(meta);
    final p = composer.paths(appearance);
    Future<RgbaImage?> opt(String? path) async =>
        path == null ? null : await image(path);
    final layers = SpriteLayers(
      body: await image(p.body),
      outfit: await opt(p.outfit),
      hair: await opt(p.hair),
      beard: await opt(p.beard),
      weapon: await opt(p.weapon),
    );
    final out = composer.compose(appearance, layers);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      out.pixels,
      out.width,
      out.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return await completer.future;
  }
}

class _SpriteCharacter extends StatefulWidget {
  const _SpriteCharacter({
    required this.appearance,
    required this.scene,
    this.snapshots,
    super.key,
  });

  final CharacterAppearance appearance;
  final CharacterScene scene;
  final CharacterSnapshotController? snapshots;

  @override
  State<_SpriteCharacter> createState() => _SpriteCharacterState();
}

class _SpriteCharacterState extends State<_SpriteCharacter> {
  ui.Image? _image;
  SpriteMeta? _meta;
  bool _failed = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    widget.snapshots?.handler = _capture;
    unawaited(_render());
  }

  @override
  void didUpdateWidget(covariant _SpriteCharacter old) {
    super.didUpdateWidget(old);
    if (old.snapshots != widget.snapshots) {
      if (old.snapshots?.handler == _capture) old.snapshots?.handler = null;
      widget.snapshots?.handler = _capture;
    }
    if (old.appearance != widget.appearance) unawaited(_render());
  }

  @override
  void dispose() {
    if (widget.snapshots?.handler == _capture) widget.snapshots?.handler = null;
    _image?.dispose();
    super.dispose();
  }

  Future<void> _render() async {
    final request = ++_request;
    try {
      final atlas = await SpriteAtlas.load();
      final image = await atlas.render(widget.appearance);
      if (!mounted || request != _request) {
        image.dispose();
        return;
      }
      setState(() {
        _image?.dispose();
        _image = image;
        _meta = atlas.meta;
        _failed = false;
      });
    } on Object {
      if (mounted && request == _request) setState(() => _failed = true);
    }
  }

  /// Capture PNG : le personnage et son décor, quatre fois plus grand.
  Future<Uint8List?> _capture() async {
    final image = _image;
    final meta = _meta;
    if (image == null || meta == null) return null;
    const scale = 4.0;
    final size = Size(meta.width * scale, meta.height * scale);
    final recorder = ui.PictureRecorder();
    _CharacterPainter(
      image: image,
      meta: meta,
      appearance: widget.appearance,
      scene: widget.scene,
    ).paint(Canvas(recorder), size);
    final shot = await recorder.endRecording().toImage(
      size.width.round(),
      size.height.round(),
    );
    final png = await shot.toByteData(format: ui.ImageByteFormat.png);
    shot.dispose();
    return png?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final image = _image;
    final meta = _meta;
    if (_failed) return Center(child: Text(l10n.characterPreviewError));
    if (image == null || meta == null) {
      return Center(child: Text(l10n.characterPreviewLoading));
    }
    return CustomPaint(
      size: Size.infinite,
      painter: _CharacterPainter(
        image: image,
        meta: meta,
        appearance: widget.appearance,
        scene: widget.scene,
      ),
    );
  }
}

class _CharacterPainter extends CustomPainter {
  _CharacterPainter({
    required this.image,
    required this.meta,
    required this.appearance,
    required this.scene,
  });

  final ui.Image image;
  final SpriteMeta meta;
  final CharacterAppearance appearance;
  final CharacterScene scene;

  static const Map<SceneLighting, List<Color>> _backdrops = {
    SceneLighting.day: [Color(0xFF9CC3E0), Color(0xFFE8D9B0)],
    SceneLighting.night: [Color(0xFF0E1530), Color(0xFF2A2F52)],
    SceneLighting.tavern: [Color(0xFF2A1A10), Color(0xFF6A4220)],
  };

  /// Teintes des Ombres (silhouettes derrière le héros), par numéro.
  static const List<Color> _shadowTints = [
    Color(0xFF3A2A6A),
    Color(0xFF2A4A6A),
    Color(0xFF5A2A4A),
    Color(0xFF2A5A4A),
    Color(0xFF4A4A2A),
    Color(0xFF5A3A2A),
    Color(0xFF2A2A5A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = _backdrops[scene.lighting]!;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );
    // Cadrage : tout le corps, ou le visage.
    final body = meta.bodies[appearance.bodyId];
    final src = scene.focus == SceneFocus.face && body != null
        ? Rect.fromCenter(
            center: Offset(
              body.skull.centre,
              body.skull.top + body.skull.width * 0.7,
            ),
            width: body.skull.width * 2.6,
            height: body.skull.width * 2.6,
          )
        : Rect.fromLTWH(0, 0, meta.width.toDouble(), meta.height.toDouble());
    final scale = (size.width / src.width) < (size.height / src.height)
        ? size.width / src.width
        : size.height / src.height;
    final dst = Rect.fromCenter(
      center: rect.center,
      width: src.width * scale,
      height: src.height * scale,
    );
    final aura = appearance.auraColor;
    if (aura != null) {
      canvas.drawOval(
        dst.deflate(dst.width * 0.12),
        Paint()
          ..color = Color(aura).withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, dst.width * 0.08),
      );
    }
    // Ombres : silhouettes teintes, un peu en retrait de chaque côté.
    for (var i = 0; i < appearance.shadows.length; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final rank = i ~/ 2 + 1;
      final shift = Offset(side * dst.width * 0.16 * rank, -dst.height * 0.02);
      final shadowRect = Rect.fromCenter(
        center: dst.center + shift,
        width: dst.width * (1 - 0.08 * rank),
        height: dst.height * (1 - 0.08 * rank),
      );
      final tint = _shadowTints[appearance.shadows[i] % _shadowTints.length];
      canvas.drawImageRect(
        image,
        src,
        shadowRect,
        Paint()
          ..filterQuality = FilterQuality.none
          ..colorFilter = ColorFilter.mode(
            tint.withValues(alpha: 0.7),
            BlendMode.srcIn,
          ),
      );
    }
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _CharacterPainter old) =>
      old.image != image || old.scene != scene || old.appearance != appearance;
}
