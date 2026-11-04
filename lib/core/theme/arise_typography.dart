import 'package:arise/core/theme/arise_colors.dart';
import 'package:flutter/material.dart';

/// Typographie d'Arisia.
///
/// - Cinzel (OFL) : titres, boutons, en-têtes du Système.
/// - IM Fell English (OFL) : textes d'ambiance (citations, récits).
/// - Police du système : corps de texte, pour une lisibilité maximale.
abstract final class AriseTypography {
  static const display = 'Cinzel';
  static const flavor = 'IMFellEnglish';

  /// Graisse de la police variable Cinzel (axe « wght »).
  static List<FontVariation> weight(double value) => [
    FontVariation('wght', value),
  ];

  static TextTheme textTheme() {
    TextStyle cinzel(double size, double wght) => TextStyle(
      fontFamily: display,
      fontSize: size,
      fontVariations: weight(wght),
      color: AriseColors.parchment,
      letterSpacing: 0.5,
    );

    const body = TextStyle(color: AriseColors.parchment, height: 1.4);

    return TextTheme(
      displayLarge: cinzel(48, 700),
      displayMedium: cinzel(40, 700),
      displaySmall: cinzel(32, 700),
      headlineLarge: cinzel(28, 700),
      headlineMedium: cinzel(24, 600),
      headlineSmall: cinzel(20, 600),
      titleLarge: cinzel(20, 600),
      titleMedium: cinzel(16, 600),
      titleSmall: cinzel(14, 600),
      labelLarge: cinzel(15, 700),
      bodyLarge: body.copyWith(fontSize: 16),
      bodyMedium: body.copyWith(fontSize: 14),
      bodySmall: body.copyWith(fontSize: 12, color: AriseColors.parchmentMuted),
      labelMedium: body.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      labelSmall: body.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
    );
  }

  /// Style des textes d'ambiance.
  static const flavorStyle = TextStyle(
    fontFamily: flavor,
    fontStyle: FontStyle.italic,
    fontSize: 17,
    height: 1.4,
    color: AriseColors.parchment,
  );
}
