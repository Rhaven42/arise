import 'dart:async';
import 'dart:convert';

import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/domain/character_scene.dart';
import 'package:arise/features/avatar/presentation/character_renderer.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Rendu 3D hors ligne : page `assets/viewer/index.html` (three.js) dans une
/// vue web, alimentée avec les modèles `assets/models/<id>.glb`.
class WebViewCharacterRenderer implements CharacterRenderer {
  const WebViewCharacterRenderer();

  @override
  Widget build({
    required CharacterAppearance appearance,
    CharacterScene scene = const CharacterScene(),
    CharacterSnapshotController? snapshots,
    Key? key,
  }) => _WebViewCharacter(
    appearance: appearance,
    scene: scene,
    snapshots: snapshots,
    key: key,
  );
}

/// Taille des morceaux de modèle envoyés à la vue web (caractères base64).
const int _chunkLength = 262144;

class _WebViewCharacter extends StatefulWidget {
  const _WebViewCharacter({
    required this.appearance,
    required this.scene,
    this.snapshots,
    super.key,
  });

  final CharacterAppearance appearance;
  final CharacterScene scene;
  final CharacterSnapshotController? snapshots;

  @override
  State<_WebViewCharacter> createState() => _WebViewCharacterState();
}

class _WebViewCharacterState extends State<_WebViewCharacter> {
  late final WebViewController _controller;
  final Set<String> _loaded = {};
  String? _loading;
  bool _ready = false;
  bool _failed = false;
  bool _shown = false;
  Completer<Uint8List?>? _pendingCapture;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    widget.snapshots?.handler = _capture;
    unawaited(_setUp());
  }

  @override
  void dispose() {
    if (widget.snapshots?.handler == _capture) widget.snapshots?.handler = null;
    _pendingCapture?.complete(null);
    super.dispose();
  }

  Future<Uint8List?> _capture() async {
    if (!_ready || !_shown) return null;
    final pending = _pendingCapture;
    if (pending != null) return await pending.future;
    final completer = _pendingCapture = Completer<Uint8List?>();
    try {
      await _controller.runJavaScript('arise.capture()');
    } on Object {
      _pendingCapture = null;
      return null;
    }
    return await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _pendingCapture = null;
        return null;
      },
    );
  }

  Future<void> _setUp() async {
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setBackgroundColor(Colors.transparent);
    await _controller.addJavaScriptChannel(
      'AriseViewer',
      onMessageReceived: _onMessage,
    );
    await _controller.loadFlutterAsset('assets/viewer/index.html');
  }

  @override
  void didUpdateWidget(covariant _WebViewCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshots != widget.snapshots) {
      if (oldWidget.snapshots?.handler == _capture) {
        oldWidget.snapshots?.handler = null;
      }
      widget.snapshots?.handler = _capture;
    }
    if (oldWidget.appearance != widget.appearance ||
        oldWidget.scene != widget.scene) {
      unawaited(_sync());
    }
  }

  void _onMessage(JavaScriptMessage message) {
    final Object? data;
    try {
      data = jsonDecode(message.message);
    } on FormatException {
      return;
    }
    if (data is! Map<String, dynamic>) return;
    switch (data['type']) {
      case 'ready':
        _ready = true;
        unawaited(_sync());
      case 'loaded':
        _loaded.add('${data['id']}');
        _loading = null;
        unawaited(_sync());
      case 'applied':
        if (mounted && !_shown) setState(() => _shown = true);
      case 'capture':
        final completer = _pendingCapture;
        _pendingCapture = null;
        if (completer == null || completer.isCompleted) return;
        final url = '${data['data']}';
        final comma = url.indexOf(',');
        try {
          completer.complete(
            comma < 0 ? null : base64Decode(url.substring(comma + 1)),
          );
        } on FormatException {
          completer.complete(null);
        }
      case 'error':
        _loading = null;
        if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _sync() async {
    if (!_ready || !mounted) return;
    final appearance = widget.appearance;
    final id = appearance.modelId;
    try {
      if (!_loaded.contains(id)) {
        // Un seul envoi à la fois : le suivant part quand le modèle en cours
        // est chargé (message « loaded »).
        if (_loading != null) return;
        _loading = id;
        final bytes = await rootBundle.load('assets/models/$id.glb');
        final encoded = base64Encode(bytes.buffer.asUint8List());
        await _controller.runJavaScript("arise.beginModel('$id')");
        for (var i = 0; i < encoded.length; i += _chunkLength) {
          final end = i + _chunkLength < encoded.length
              ? i + _chunkLength
              : encoded.length;
          await _controller.runJavaScript(
            "arise.appendChunk('$id', '${encoded.substring(i, end)}')",
          );
        }
        await _controller.runJavaScript("arise.endModel('$id')");
        return;
      }
      final state = jsonEncode({
        'model': id,
        'morphs': appearance.morphs,
        'scale': appearance.scale,
        'skinColor': _hex(appearance.skinColor),
        'hairColor': _hex(appearance.hairColor),
        'hairNode': appearance.hairStyleId,
        'eyeColor': _hex(appearance.eyeColor),
        'beardColor': _hex(appearance.beardColor),
        'browNode': appearance.eyebrowId,
        'beardNode': appearance.beardId,
        'makeupNode': appearance.makeupId,
        'lighting': widget.scene.lighting.name,
        'focus': widget.scene.focus.name,
        'outfit': true,
        'items': appearance.itemNodes,
        'hiddenOutfit': appearance.hiddenOutfit,
        'dyes': {for (final e in appearance.dyes.entries) e.key: _hex(e.value)},
        'aura': switch (appearance.auraColor) {
          final color? => _hex(color),
          null => null,
        },
        'shadows': appearance.shadows,
      });
      await _controller.runJavaScript('arise.apply(${jsonEncode(state)})');
    } on Object {
      // Le rendu ne doit jamais bloquer le créateur : la fiche reste
      // modifiable même si la vue 3D échoue.
      _loading = null;
      if (mounted) setState(() => _failed = true);
    }
  }

  static const _gestures = {
    Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
  };

  static String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller, gestureRecognizers: _gestures),
        if (_failed)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.characterPreviewError,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else if (!_shown)
          Center(child: Text(l10n.characterPreviewLoading)),
      ],
    );
  }
}
