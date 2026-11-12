import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/pin_dialog.dart';
import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/account/domain/account.dart';
import 'package:arise/features/account/domain/account_rules.dart';
import 'package:arise/features/account/presentation/account_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Choix du compte à ouvrir (code PIN demandé si le compte en a un).
class AccountPickerPage extends ConsumerWidget {
  const AccountPickerPage({super.key});

  static Key accountKey(String id) => Key('account-$id');
  static const newKey = Key('account-new');

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(accountsControllerProvider.notifier);
    final ok = account.hasPin
        ? await askPin(
            context,
            title: l10n.accountPinPromptTitle(
              account.displayName(l10n.accountUnnamed),
            ),
            check: (pin) => controller.switchTo(account.id, pin: pin),
          )
        : await controller.switchTo(account.id);
    if (ok && context.mounted) context.go(AppRoutes.title);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(accountsControllerProvider).value;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.title)),
        title: Text(l10n.accountPickerTitle),
      ),
      body: view == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AriseSpacing.md),
              children: [
                for (final account in view.accounts) ...[
                  StoneFrame(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      key: accountKey(account.id),
                      leading: CircleAvatar(
                        backgroundColor: AriseColors.goldDeep,
                        foregroundColor: AriseColors.onGold,
                        child: Text(
                          account
                              .displayName(l10n.accountUnnamed)
                              .characters
                              .first
                              .toUpperCase(),
                        ),
                      ),
                      title: Text(account.displayName(l10n.accountUnnamed)),
                      trailing: account.hasPin
                          ? Icon(
                              Icons.lock_outline,
                              semanticLabel: l10n.accountLockedSemantics,
                            )
                          : null,
                      selected: account.id == view.active?.id,
                      onTap: () => _open(context, ref, account),
                    ),
                  ),
                  const SizedBox(height: AriseSpacing.sm),
                ],
                if (canCreateAccount(view.accounts)) ...[
                  const SizedBox(height: AriseSpacing.md),
                  AriseButton(
                    key: newKey,
                    label: l10n.accountNewButton,
                    icon: Icons.person_add_alt_1,
                    variant: AriseButtonVariant.secondary,
                    onPressed: () => context.go(AppRoutes.accountNew),
                  ),
                ],
              ],
            ),
    );
  }
}
