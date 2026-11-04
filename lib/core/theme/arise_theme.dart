import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/theme/arise_typography.dart';
import 'package:flutter/material.dart';

/// Thème sombre et chaud d'ARISE (Material 3 personnalisé).
abstract final class AriseTheme {
  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AriseColors.gold,
      onPrimary: AriseColors.onGold,
      secondary: AriseColors.ember,
      onSecondary: AriseColors.onGold,
      tertiary: AriseColors.mana,
      onTertiary: AriseColors.abyss,
      error: AriseColors.danger,
      onError: AriseColors.abyss,
      surface: AriseColors.stone,
      onSurface: AriseColors.parchment,
      surfaceContainerHighest: AriseColors.stoneLight,
      outline: AriseColors.woodLight,
    );

    final textTheme = AriseTypography.textTheme();
    const minSize = Size.square(AriseSpacing.minTouchTarget);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AriseSpacing.radius),
    );
    const padding = EdgeInsets.symmetric(
      horizontal: AriseSpacing.lg,
      vertical: AriseSpacing.sm,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AriseColors.abyss,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AriseColors.stoneDark,
        foregroundColor: AriseColors.parchment,
        titleTextStyle: textTheme.titleLarge,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AriseColors.gold,
          foregroundColor: AriseColors.onGold,
          disabledBackgroundColor: AriseColors.stoneLight,
          disabledForegroundColor: AriseColors.parchment,
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AriseColors.gold,
          disabledForegroundColor: AriseColors.parchmentMuted,
          side: const BorderSide(color: AriseColors.gold, width: 1.5),
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      dividerTheme: const DividerThemeData(color: AriseColors.stoneLight),
    );
  }
}
