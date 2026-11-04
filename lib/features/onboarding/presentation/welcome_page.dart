import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/theme/arise_typography.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Écran d'accueil (remplacé par l'écran titre de la taverne en phase 1).
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 1.1,
            colors: [AriseColors.wood, AriseColors.abyss],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AriseSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.appTitle,
                      style: textTheme.displayLarge?.copyWith(
                        color: AriseColors.goldBright,
                        letterSpacing: 8,
                        shadows: const [
                          Shadow(color: AriseColors.ember, blurRadius: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AriseSpacing.md),
                  Text(
                    l10n.welcomeTagline,
                    textAlign: TextAlign.center,
                    style: AriseTypography.flavorStyle,
                  ),
                  const SizedBox(height: AriseSpacing.xl),
                  AriseButton(
                    label: l10n.welcomeDesignSystemButton,
                    icon: Icons.auto_awesome,
                    onPressed: () => context.go(AppRoutes.designSystem),
                  ),
                  const SizedBox(height: AriseSpacing.lg),
                  Text(l10n.welcomeBuildInfo, style: textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
