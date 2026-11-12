import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/account/domain/account_rules.dart';
import 'package:arise/features/account/presentation/account_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Message d'un pseudo refusé.
String accountIssueText(AppLocalizations l10n, AccountNameIssue issue) =>
    l10n.accountNameIssue(issue.name, gameConfig.account.nameMaxLength);

/// Création d'un compte local : pseudo et code PIN facultatif. Ensuite,
/// l'Éveil (ou la restauration d'une sauvegarde si [restore]).
class AccountCreatePage extends ConsumerStatefulWidget {
  const AccountCreatePage({this.restore = false, super.key});

  final bool restore;

  static const nameKey = Key('account-name');
  static const pinToggleKey = Key('account-pin-toggle');
  static const pinKey = Key('account-pin');
  static const pinConfirmKey = Key('account-pin-confirm');
  static const createKey = Key('account-create');

  @override
  ConsumerState<AccountCreatePage> createState() => _AccountCreatePageState();
}

class _AccountCreatePageState extends ConsumerState<AccountCreatePage> {
  final _name = TextEditingController();
  final _pin = TextEditingController();
  final _pinConfirm = TextEditingController();
  bool _usePin = false;
  String? _nameError;
  String? _pinError;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _pin.dispose();
    _pinConfirm.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final digits = gameConfig.account.pinLength;
    String? pinError;
    if (_usePin && !isValidPin(_pin.text)) {
      pinError = l10n.accountPinInvalid(digits);
    } else if (_usePin && _pin.text != _pinConfirm.text) {
      pinError = l10n.accountPinMismatch;
    }
    setState(() {
      _pinError = pinError;
      _nameError = null;
    });
    if (pinError != null) return;
    setState(() => _busy = true);
    final issue = await ref
        .read(accountsControllerProvider.notifier)
        .create(_name.text, pin: _usePin ? _pin.text : null);
    if (!mounted) return;
    if (issue != null) {
      setState(() {
        _nameError = accountIssueText(l10n, issue);
        _busy = false;
      });
      return;
    }
    context.go(widget.restore ? AppRoutes.restore : AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final digits = gameConfig.account.pinLength;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.title)),
        title: Text(l10n.accountCreateTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AriseSpacing.md),
        children: [
          Text(l10n.accountCreateIntro, style: textTheme.bodyLarge),
          const SizedBox(height: AriseSpacing.lg),
          TextField(
            key: AccountCreatePage.nameKey,
            controller: _name,
            maxLength: gameConfig.account.nameMaxLength,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.accountNameLabel,
              errorText: _nameError,
            ),
          ),
          SwitchListTile(
            key: AccountCreatePage.pinToggleKey,
            contentPadding: EdgeInsets.zero,
            value: _usePin,
            title: Text(l10n.accountPinToggle),
            subtitle: Text(l10n.accountPinToggleHint),
            onChanged: (value) => setState(() => _usePin = value),
          ),
          if (_usePin) ...[
            TextField(
              key: AccountCreatePage.pinKey,
              controller: _pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: digits,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.accountPinLabel(digits),
              ),
            ),
            TextField(
              key: AccountCreatePage.pinConfirmKey,
              controller: _pinConfirm,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: digits,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.accountPinConfirmLabel,
                errorText: _pinError,
              ),
            ),
          ],
          const SizedBox(height: AriseSpacing.lg),
          AriseButton(
            key: AccountCreatePage.createKey,
            label: l10n.accountCreateButton,
            icon: Icons.person_add_alt_1,
            onPressed: _busy ? null : _create,
          ),
        ],
      ),
    );
  }
}
