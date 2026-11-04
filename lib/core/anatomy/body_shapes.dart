import 'package:arise/core/anatomy/muscle.dart';

/// Commande d'un tracé SVG (absolue) : `M`, `L`, `C` ou `Z`.
class PathCommand {
  const PathCommand(this.op, this.args);

  final String op;
  final List<double> args;
}

/// Tracé SVG décodé.
typedef SvgPathData = List<PathCommand>;

/// Silhouette d'une vue : contour du corps et zones musculaires.
class BodyShapes {
  const BodyShapes({
    required this.view,
    required this.width,
    required this.height,
    required this.outline,
    required this.zones,
  });

  final BodyView view;
  final double width;
  final double height;
  final SvgPathData outline;
  final Map<MuscleId, List<SvgPathData>> zones;
}

/// Erreur levée quand une silhouette SVG ne respecte pas le format attendu.
class BodyShapesFormatException implements Exception {
  const BodyShapesFormatException(this.message);

  final String message;

  @override
  String toString() => 'BodyShapesFormatException($message)';
}

/// Lecteur des silhouettes SVG d'ARISE (`assets/svg/body_*.svg`).
///
/// Le format est volontairement restreint (généré par l'outil interne) :
/// un `<path id="outline">` et un `<g id="<muscle>">` par muscle, avec des
/// commandes absolues M, L, C et Z.
abstract final class BodyShapesParser {
  static final _viewBox = RegExp(r'viewBox="0 0 ([\d.]+) ([\d.]+)"');
  static final _outline = RegExp(r'<path id="outline" d="([^"]+)"');
  static final _group = RegExp(r'<g id="([a-z_]+)">(.*?)</g>', dotAll: true);
  static final _pathData = RegExp(r'<path d="([^"]+)"');
  static final _token = RegExp(r'[MLCZ]|-?\d+(?:\.\d+)?');

  static BodyShapes parse(String svg, BodyView view) {
    final box = _viewBox.firstMatch(svg);
    final outline = _outline.firstMatch(svg);
    if (box == null || outline == null) {
      throw const BodyShapesFormatException('viewBox ou contour manquant');
    }
    final zones = <MuscleId, List<SvgPathData>>{};
    for (final group in _group.allMatches(svg)) {
      final muscle = MuscleId.tryParse(group.group(1)!);
      if (muscle == null) {
        throw BodyShapesFormatException('muscle inconnu : ${group.group(1)}');
      }
      zones[muscle] = [
        for (final path in _pathData.allMatches(group.group(2)!))
          parsePathData(path.group(1)!),
      ];
    }
    return BodyShapes(
      view: view,
      width: double.parse(box.group(1)!),
      height: double.parse(box.group(2)!),
      outline: parsePathData(outline.group(1)!),
      zones: zones,
    );
  }

  /// Décode l'attribut `d` d'un tracé.
  static SvgPathData parsePathData(String data) {
    const arity = {'M': 2, 'L': 2, 'C': 6, 'Z': 0};
    final tokens = [for (final m in _token.allMatches(data)) m.group(0)!];
    final commands = <PathCommand>[];
    var i = 0;
    while (i < tokens.length) {
      final op = tokens[i++];
      final count = arity[op];
      if (count == null || i + count > tokens.length) {
        throw BodyShapesFormatException('commande invalide : $op');
      }
      commands.add(
        PathCommand(op, [
          for (var k = 0; k < count; k++) double.parse(tokens[i + k]),
        ]),
      );
      i += count;
    }
    return commands;
  }
}
