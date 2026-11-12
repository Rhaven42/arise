import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_typography.dart';
import 'package:flutter/material.dart';

/// Gemme d'une stat : losange coloré serti d'or, valeur au centre et nom
/// dessous (la couleur n'est jamais la seule information).
class StatGem extends StatelessWidget {
  const StatGem({
    required this.color,
    required this.value,
    required this.label,
    required this.semanticsLabel,
    super.key,
  });

  final Color color;
  final int value;
  final String label;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: Transform.rotate(
                angle: 0.785398,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: RadialGradient(
                      colors: [
                        Color.lerp(color, Colors.white, 0.15)!,
                        Color.lerp(color, Colors.black, 0.55)!,
                      ],
                    ),
                    border: Border.all(color: AriseColors.gold, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                  child: Transform.rotate(
                    angle: -0.785398,
                    child: Center(
                      child: Text(
                        '$value',
                        style: TextStyle(
                          fontFamily: AriseTypography.display,
                          fontVariations: AriseTypography.weight(800),
                          fontSize: 16,
                          color: Colors.white,
                          shadows: const [Shadow(blurRadius: 3)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AriseTypography.display,
                fontVariations: AriseTypography.weight(700),
                fontSize: 10,
                letterSpacing: 0.5,
                color: AriseColors.parchmentMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
