import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/admin.dart';

/// Password input with show/hide and the server's password rules.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.username,
    this.helperText,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;

  /// Current username, so "same as username" can be refused.
  final String Function()? username;
  final String? helperText;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      obscureText: _obscure,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const [AutofillHints.newPassword],
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        helperMaxLines: 3,
        suffixIcon: IconButton(
          tooltip: _obscure ? l10n.loginShowPassword : l10n.loginHidePassword,
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: (value) => switch (NewStaff.passwordIssue(value ?? '', username: widget.username?.call())) {
        PasswordIssue.tooShort => l10n.validationPasswordShort,
        PasswordIssue.tooLong => l10n.validationPasswordLong,
        PasswordIssue.sameAsUsername => l10n.validationPasswordSameAsUsername,
        null => null,
      },
    );
  }
}

/// Asks the owner for a new password. Returns it on confirm, null on cancel.
/// The dialog owns its controller, so nothing is disposed while it animates.
Future<String?> showNewPasswordDialog(BuildContext context, {required String name}) => showDialog<String>(
  context: context,
  builder: (_) => _NewPasswordDialog(name: name),
);

class _NewPasswordDialog extends StatefulWidget {
  const _NewPasswordDialog({required this.name});

  final String name;

  @override
  State<_NewPasswordDialog> createState() => _NewPasswordDialogState();
}

class _NewPasswordDialogState extends State<_NewPasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_form.currentState?.validate() ?? false) Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.staffResetPassword),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.staffResetPasswordBody(widget.name)),
            const SizedBox(height: 12),
            PasswordField(
              controller: _password,
              label: l10n.fieldNewPassword,
              autofocus: true,
              onSubmitted: (_) => _confirm(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonCancel)),
        FilledButton(onPressed: _confirm, child: Text(l10n.commonSave)),
      ],
    );
  }
}
