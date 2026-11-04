import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/theme/arise_typography.dart';
import 'package:arise/features/onboarding/presentation/widgets/tavern_backdrop.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Écran titre : la taverne d'Arisia.
class TitlePage extends ConsumerWidget {
  const TitlePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final profile = ref.watch(playerProfileProvider);

    final actions = switch (profile) {
      AsyncData(:final value) when value != null => [
        AriseButton(
          label: l10n.titleContinueButton,
          icon: Icons.login,
          onPressed: () => context.go(AppRoutes.systemHome),
        ),
      ],
      AsyncData() || AsyncError() => [
        AriseButton(
          label: l10n.titleStartButton,
          icon: Icons.local_fire_department_outlined,
          onPressed: () => context.go(AppRoutes.onboarding),
        ),
        const SizedBox(height: AriseSpacing.sm),
        AriseButton(
          label: l10n.titleRestoreButton,
          variant: AriseButtonVariant.secondary,
          icon: Icons.restore,
          onPressed: () => context.go(AppRoutes.restore),
        ),
      ],
      _ => const [
        Center(child: CircularProgressIndicator(color: AriseColors.gold)),
      ],
    };

    return Scaffold(
      body: TavernBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AriseSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.appTitle,
                        textAlign: TextAlign.center,
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
                    ...actions,
                    if (kDebugMode) ...[
                      const SizedBox(height: AriseSpacing.lg),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.designSystem),
                        child: Text(l10n.welcomeDesignSystemButton),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
