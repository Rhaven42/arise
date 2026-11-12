import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/account/domain/account_rules.dart';
import 'package:arise/features/account/presentation/account_create_page.dart';
import 'package:arise/features/account/presentation/account_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Réglages du compte actif : pseudo, code PIN, changement et suppression.
class AccountSettingsPage extends ConsumerStatefulWidget {
  const AccountSettingsPage({super.key});

  static const nameKey = Key('account-settings-name');
  static const deleteKey = Key('account-delete');

  @override
  ConsumerState<AccountSettingsPage> createState() =>
      _AccountSettingsPageState();
}

class _AccountSettingsPageState extends ConsumerState<AccountSettingsPage> {
  final _name = TextEditingController();
  String? _nameError;
  String? _loadedFor;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _rename() async {
    final l10n = AppLocalizations.of(context);
    final issue = await ref
        .read(accountsControllerProvider.notifier)
        .rename(_name.text);
    if (!mounted) return;
    setState(
      () => _nameError = issue == null ? null : accountIssueText(l10n, issue),
    );
    if (issue == null) _snack(l10n.accountRenamed);
  }

  Future<void> _editPin() async {
    final l10n = AppLocalizations.of(context);
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => const _NewPinDialog(),
    );
    if (pin == null || !mounted) return;
    await ref.read(accountsControllerProvider.notifier).setPin(pin);
    if (mounted) _snack(l10n.accountPinSaved);
  }

  Future<void> _removePin() async {
    final l10n = AppLocalizations.of(context);
    await ref.read(accountsControllerProvider.notifier).setPin(null);
    if (mounted) _snack(l10n.accountPinRemoved);
  }

  Future<void> _delete(String id, String name) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountDeleteTitle(name)),
        content: Text(l10n.accountDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.accountCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AriseColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.accountDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // Quitte d'abord les écrans du jeu, puis efface le compte.
    context.go(AppRoutes.title);
    await ref.read(accountsControllerProvider.notifier).delete(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = ref.watch(accountsControllerProvider).value?.active;
    if (active != null && _loadedFor != active.id) {
      _loadedFor = active.id;
      _name.text = active.name;
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountSettingsTile)),
      body: active == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AriseSpacing.md),
              children: [
                TextField(
                  key: AccountSettingsPage.nameKey,
                  controller: _name,
                  maxLength: gameConfig.account.nameMaxLength,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.accountNameLabel,
                    errorText: _nameError,
                  ),
                ),
                AriseButton(
                  label: l10n.accountRenameButton,
                  icon: Icons.save_outlined,
                  variant: AriseButtonVariant.secondary,
                  onPressed: _rename,
                ),
                const SizedBox(height: AriseSpacing.lg),
                ListTile(
                  leading: const Icon(Icons.pin_outlined),
                  title: Text(
                    active.hasPin ? l10n.accountPinChange : l10n.accountPinSet,
                  ),
                  onTap: _editPin,
                ),
                if (active.hasPin)
                  ListTile(
                    leading: const Icon(Icons.lock_open_outlined),
                    title: Text(l10n.accountPinRemove),
                    onTap: _removePin,
                  ),
                ListTile(
                  leading: const Icon(Icons.switch_account_outlined),
                  title: Text(l10n.accountSwitchButton),
                  onTap: () => context.go(AppRoutes.accounts),
                ),
                const SizedBox(height: AriseSpacing.lg),
                ListTile(
                  key: AccountSettingsPage.deleteKey,
                  leading: const Icon(
                    Icons.delete_forever_outlined,
                    color: AriseColors.danger,
                  ),
                  title: Text(
                    l10n.accountDeleteButton,
                    style: const TextStyle(color: AriseColors.danger),
                  ),
                  onTap: () => _delete(
                    active.id,
                    active.displayName(l10n.accountUnnamed),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Saisie d'un nouveau code PIN (deux fois).
class _NewPinDialog extends StatefulWidget {
  const _NewPinDialog();

  @override
  State<_NewPinDialog> createState() => _NewPinDialogState();
}

class _NewPinDialogState extends State<_NewPinDialog> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final digits = gameConfig.account.pinLength;
    if (!isValidPin(_pin.text)) {
      setState(() => _error = l10n.accountPinInvalid(digits));
    } else if (_pin.text != _confirm.text) {
      setState(() => _error = l10n.accountPinMismatch);
    } else {
      Navigator.of(context).pop(_pin.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final digits = gameConfig.account.pinLength;
    InputDecoration field(String label, {String? error}) =>
        InputDecoration(labelText: label, errorText: error);
    return AlertDialog(
      title: Text(l10n.accountPinSet),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (controller, label, error) in [
            (_pin, l10n.accountPinLabel(digits), null),
            (_confirm, l10n.accountPinConfirmLabel, _error),
          ])
            TextField(
              controller: controller,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: digits,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: field(label, error: error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.accountCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.accountPinValidate)),
      ],
    );
  }
}
