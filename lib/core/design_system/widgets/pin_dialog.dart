import 'package:arise/core/config/game_config.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Demande un code PIN. [check] renvoie vrai si le code est accepté ; la
/// boîte se ferme alors en renvoyant vrai. Annulée, elle renvoie faux.
Future<bool> askPin(
  BuildContext context, {
  required String title,
  required Future<bool> Function(String pin) check,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => _PinDialog(title: title, check: check),
  );
  return ok ?? false;
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.title, required this.check});

  final String title;
  final Future<bool> Function(String pin) check;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _controller = TextEditingController();
  bool _wrong = false;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await widget.check(_controller.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      _controller.clear();
      setState(() {
        _wrong = true;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final digits = gameConfig.account.pinLength;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('pin-field'),
        controller: _controller,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: digits,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: l10n.accountPinLabel(digits),
          errorText: _wrong ? l10n.accountPinWrong : null,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.accountCancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(l10n.accountPinValidate),
        ),
      ],
    );
  }
}
