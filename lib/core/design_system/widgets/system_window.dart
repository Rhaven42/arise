import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/theme/arise_typography.dart';
import 'package:flutter/material.dart';

/// Fenêtre du « Système » : panneau de mana lumineux, plaque d'en-tête et
/// coins brillants, pour les quêtes, récompenses et messages.
class SystemWindow extends StatelessWidget {
  const SystemWindow({
    required this.header,
    required this.title,
    required this.child,
    super.key,
    this.actions = const [],
  });

  /// En-tête court affiché sur la plaque lumineuse (ex. « Système »).
  final String header;
  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final body = DefaultTextStyle.merge(
      style: const TextStyle(color: AriseColors.manaText),
      child: child,
    );
    return Semantics(
      container: true,
      label: '$header. $title',
      child: Padding(
        // Place pour la plaque qui chevauche le bord supérieur.
        padding: const EdgeInsets.only(top: 14),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              foregroundPainter: const CornerBracketsPainter(
                color: AriseColors.manaBright,
                length: 14,
                glow: true,
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      AriseSpacing.radius / 2,
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AriseColors.manaPanelTop,
                        AriseColors.manaPanelBottom,
                      ],
                    ),
                    border: Border.all(
                      color: AriseColors.mana.withValues(alpha: 0.7),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AriseColors.mana.withValues(alpha: 0.3),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AriseSpacing.md,
                      AriseSpacing.lg + AriseSpacing.xs,
                      AriseSpacing.md,
                      AriseSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleLarge?.copyWith(
                            color: AriseColors.manaPale,
                            fontVariations: AriseTypography.weight(700),
                            shadows: [
                              Shadow(
                                color: AriseColors.mana.withValues(alpha: 0.7),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AriseSpacing.sm),
                        body,
                        if (actions.isNotEmpty) ...[
                          const SizedBox(height: AriseSpacing.md),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: AriseSpacing.sm,
                            runSpacing: AriseSpacing.sm,
                            children: actions,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: ExcludeSemantics(child: _Plaque(text: header)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Plaque hexagonale lumineuse de l'en-tête.
class _Plaque extends StatelessWidget {
  const _Plaque({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AriseColors.mana.withValues(alpha: 0.6),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipPath(
        clipper: const _HexClipper(),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B4B6E), AriseColors.manaDeep],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 5),
            child: Text(
              text.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFFDFF6FF),
                letterSpacing: 4,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HexClipper extends CustomClipper<Path> {
  const _HexClipper();

  @override
  Path getClip(Size size) {
    final d = size.height / 2;
    return Path()
      ..moveTo(d, 0)
      ..lineTo(size.width - d, 0)
      ..lineTo(size.width, d)
      ..lineTo(size.width - d, size.height)
      ..lineTo(d, size.height)
      ..lineTo(0, d)
      ..close();
  }

  @override
  bool shouldReclip(covariant _HexClipper oldClipper) => false;
}
