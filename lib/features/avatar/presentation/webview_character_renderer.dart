import 'dart:async';
import 'dart:convert';

import 'package:arise/features/avatar/domain/character_appearance.dart';
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
  Widget build({required CharacterAppearance appearance, Key? key}) =>
      _WebViewCharacter(appearance: appearance, key: key);
}

/// Taille des morceaux de modèle envoyés à la vue web (caractères base64).
const int _chunkLength = 262144;

class _WebViewCharacter extends StatefulWidget {
  const _WebViewCharacter({required this.appearance, super.key});

  final CharacterAppearance appearance;

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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    unawaited(_setUp());
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
    if (oldWidget.appearance != widget.appearance) unawaited(_sync());
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
        if (_loading == id) return;
        _loading = id;
        final bytes = await rootBundle.load('assets/models/$id.glb');
        final encoded = base64Encode(bytes.buffer.asUint8List());
        await _controller.runJavaScript("arise.beginModel('$id')");
        for (var i = 0; i < encoded.length; i += _chunkLength) {
          final end = i + _chunkLength < encoded.length
              ? i + _chunkLength
              : encoded.length;
          await _controller.runJavaScript(
            "arise.appendChunk('${encoded.substring(i, end)}')",
          );
        }
        await _controller.runJavaScript('arise.endModel()');
        return;
      }
      final state = jsonEncode({
        'model': id,
        'morphs': appearance.morphs,
        'scale': appearance.scale,
        'skinColor': _hex(appearance.skinColor),
        'hairColor': _hex(appearance.hairColor),
        'hairNode': appearance.hairStyleId,
        'outfit': true,
      });
      await _controller.runJavaScript('arise.apply(${jsonEncode(state)})');
    } on Object {
      // Le rendu ne doit jamais bloquer le créateur : la fiche reste
      // modifiable même si la vue 3D échoue.
      _loading = null;
      if (mounted) setState(() => _failed = true);
    }
  }

  static String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(
          controller: _controller,
          gestureRecognizers: const {
            Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
          },
        ),
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
