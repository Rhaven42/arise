import 'package:arise/core/design_system/widgets/arise_backdrop.dart';
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
      // Pages transparentes : le fond de pierre est peint sous chaque page
      // par la transition (voir AriseBackdropTransitionsBuilder).
      scaffoldBackgroundColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AriseBackdropTransitionsBuilder(),
          TargetPlatform.iOS: AriseBackdropTransitionsBuilder(),
          TargetPlatform.linux: AriseBackdropTransitionsBuilder(),
          TargetPlatform.macOS: AriseBackdropTransitionsBuilder(),
          TargetPlatform.windows: AriseBackdropTransitionsBuilder(),
          TargetPlatform.fuchsia: AriseBackdropTransitionsBuilder(),
        },
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AriseColors.panelBottom.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        foregroundColor: AriseColors.goldBright,
        iconTheme: const IconThemeData(color: AriseColors.gold),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AriseColors.goldBright,
          letterSpacing: 1.5,
          shadows: const [Shadow(blurRadius: 4)],
        ),
        centerTitle: true,
        shape: const Border(bottom: BorderSide(color: AriseColors.bronzeEdge)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AriseColors.onGold,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: AriseColors.parchmentMuted,
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          textStyle: textTheme.labelLarge,
        ).copyWith(backgroundBuilder: _metalGold),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AriseColors.goldBright,
          disabledForegroundColor: AriseColors.parchmentMuted,
          side: const BorderSide(color: AriseColors.gold, width: 1.5),
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          textStyle: textTheme.labelLarge,
        ).copyWith(backgroundBuilder: _darkPlate),
      ),
      cardTheme: const CardThemeData(
        color: AriseColors.panelTop,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AriseColors.bronzeEdge),
          borderRadius: BorderRadius.all(Radius.circular(AriseSpacing.radius)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AriseColors.bronzeEdge),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AriseColors.goldBright, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AriseColors.stoneLight),
      chipTheme: ChipThemeData(
        backgroundColor: AriseColors.stone,
        selectedColor: AriseColors.gold,
        checkmarkColor: AriseColors.onGold,
        side: const BorderSide(color: AriseColors.woodLight),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AriseColors.onGold
                : AriseColors.parchment,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AriseSpacing.sm,
          vertical: AriseSpacing.xs,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AriseColors.stoneLight,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AriseColors.panelTop,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AriseColors.gold),
          borderRadius: BorderRadius.circular(AriseSpacing.radius),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
    );
  }

  /// Fond d'or métallique des boutons principaux (relief, reflet, lueur).
  static Widget _metalGold(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) {
    final disabled = states.contains(WidgetState.disabled);
    final pressed = states.contains(WidgetState.pressed);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AriseSpacing.radius),
        border: Border.all(
          color: disabled ? AriseColors.stoneLight : AriseColors.goldPale,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: disabled
              ? const [AriseColors.stoneLight, AriseColors.stone]
              : pressed
              ? const [AriseColors.goldDeep, AriseColors.gold]
              : const [
                  AriseColors.goldPale,
                  AriseColors.gold,
                  AriseColors.goldDeep,
                  AriseColors.gold,
                ],
          stops: disabled || pressed ? null : const [0, 0.42, 0.6, 1],
        ),
        boxShadow: disabled
            ? null
            : [
                const BoxShadow(color: AriseColors.goldShadow, spreadRadius: 1),
                BoxShadow(
                  color: AriseColors.goldBright.withValues(
                    alpha: pressed ? 0.1 : 0.18,
                  ),
                  blurRadius: 8,
                ),
              ],
      ),
      child: child,
    );
  }

  /// Fond des boutons secondaires : plaque sombre bordée d'or.
  static Widget _darkPlate(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AriseSpacing.radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: states.contains(WidgetState.pressed)
              ? const [AriseColors.panelBottom, AriseColors.panelTop]
              : const [AriseColors.panelTop, AriseColors.panelBottom],
        ),
      ),
      child: child,
    );
  }
}
