import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/world_palette.dart';
import 'package:flutter/material.dart';

/// Fond des pages : le décor en pixel art de l'univers actif, voilé de
/// sombre (plus en bas, où se lisent les listes) pour garder les textes
/// lisibles, et vignettage.
class AriseBackdrop extends StatelessWidget {
  const AriseBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AriseColors.backdropBottom,
        image: DecorationImage(
          image: AssetImage(WorldPalette.active.backdrop),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.none,
        ),
      ),
      child: CustomPaint(painter: const _VeilPainter(), child: child),
    );
  }
}

/// Voile sombre et vignettage par-dessus le décor.
class _VeilPainter extends CustomPainter {
  const _VeilPainter();

  /// Opacité du voile en haut et en bas de l'écran.
  static const _topVeil = 0.28;
  static const _bottomVeil = 0.58;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas
      ..drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AriseColors.abyss.withValues(alpha: _topVeil),
              AriseColors.abyss.withValues(alpha: _bottomVeil),
            ],
          ).createShader(rect),
      )
      ..drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            radius: 0.95,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
            stops: const [0.6, 1],
          ).createShader(rect),
      );
  }

  @override
  bool shouldRepaint(covariant _VeilPainter oldDelegate) => false;
}

/// Transition de page qui peint le fond sous chaque page (les pages sont
/// transparentes), puis la fait monter en fondu (sans capture d'écran
/// intermédiaire, plus légère que le zoom).
class AriseBackdropTransitionsBuilder extends PageTransitionsBuilder {
  const AriseBackdropTransitionsBuilder();

  static const _inner = FadeUpwardsPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _inner.buildTransitions(
    route,
    context,
    animation,
    secondaryAnimation,
    AriseBackdrop(child: child),
  );
}
