import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/pin_dialog.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/theme/arise_typography.dart';
import 'package:arise/features/account/presentation/account_providers.dart';
import 'package:arise/features/onboarding/presentation/widgets/tavern_backdrop.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Logo de l'application (blason Hero Protocol).
const String appLogoAsset = 'assets/branding/logo.webp';

/// Écran titre : la taverne d'Arisia, sous le blason de Hero Protocol.
class TitlePage extends ConsumerWidget {
  const TitlePage({super.key});

  static const logoKey = Key('title-logo');
  static const switchKey = Key('title-switch-account');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(playerProfileProvider);
    final accounts = ref.watch(accountsControllerProvider).value;
    final active = accounts?.active;

    // Ouvre une destination du compte actif, après son code PIN s'il en a.
    Future<void> enter(String location) async {
      final view = accounts;
      if (view != null && view.locked && view.active != null) {
        final ok = await askPin(
          context,
          title: l10n.accountPinPromptTitle(
            view.active!.displayName(l10n.accountUnnamed),
          ),
          check: ref.read(accountsControllerProvider.notifier).unlock,
        );
        if (!ok) return;
      }
      if (context.mounted) context.go(location);
    }

    final switchAccount = [
      const SizedBox(height: AriseSpacing.sm),
      AriseButton(
        key: TitlePage.switchKey,
        label: l10n.accountSwitchButton,
        variant: AriseButtonVariant.secondary,
        icon: Icons.switch_account_outlined,
        onPressed: () => context.go(AppRoutes.accounts),
      ),
    ];

    final actions = switch ((accounts, profile)) {
      (null, _) || (_, AsyncLoading()) => const [
        Center(child: CircularProgressIndicator(color: AriseColors.gold)),
      ],
      // Aucun compte ouvert : on en crée un (ou on en choisit un).
      (final view?, _) when view.active == null => [
        AriseButton(
          label: l10n.titleStartButton,
          icon: Icons.local_fire_department_outlined,
          onPressed: () => context.go(AppRoutes.accountNew),
        ),
        const SizedBox(height: AriseSpacing.sm),
        AriseButton(
          label: l10n.titleRestoreButton,
          variant: AriseButtonVariant.secondary,
          icon: Icons.restore,
          onPressed: () => context.go(AppRoutes.accountNewForRestore),
        ),
        if (view.accounts.isNotEmpty) ...switchAccount,
      ],
      (_, AsyncData(:final value)) when value != null => [
        AriseButton(
          label: l10n.titleContinueButton,
          icon: Icons.login,
          onPressed: () => enter(AppRoutes.systemHome),
        ),
        ...switchAccount,
      ],
      _ => [
        AriseButton(
          label: l10n.titleStartButton,
          icon: Icons.local_fire_department_outlined,
          onPressed: () => enter(AppRoutes.onboarding),
        ),
        const SizedBox(height: AriseSpacing.sm),
        AriseButton(
          label: l10n.titleRestoreButton,
          variant: AriseButtonVariant.secondary,
          icon: Icons.restore,
          onPressed: () => enter(AppRoutes.restore),
        ),
        ...switchAccount,
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
                    SizedBox(height: MediaQuery.sizeOf(context).height * 0.04),
                    Semantics(
                      header: true,
                      image: true,
                      label: l10n.appTitle,
                      child: ExcludeSemantics(
                        child: Image.asset(
                          appLogoAsset,
                          key: logoKey,
                          height: MediaQuery.sizeOf(context).height * 0.34,
                          fit: BoxFit.contain,
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
                    if (active != null) ...[
                      Text(
                        l10n.accountCurrent(
                          active.displayName(l10n.accountUnnamed),
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AriseSpacing.sm),
                    ],
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
