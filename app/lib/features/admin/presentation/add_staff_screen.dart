import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../application/admin_providers.dart';
import '../domain/admin.dart';
import 'admin_labels.dart';
import 'password_field.dart';

/// Creates a staff login. The account is made on the server (Edge Function);
/// success is shown only after it exists.
class AddStaffScreen extends ConsumerStatefulWidget {
  const AddStaffScreen({super.key});

  @override
  ConsumerState<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends ConsumerState<AddStaffScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _selected = <Permission>{};
  String? _usernameError;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _username, _password]) {
      c.addListener(_markDirty);
    }
    _username.addListener(() {
      if (_usernameError != null) setState(() => _usernameError = null);
    });
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    if (!(_form.currentState?.validate() ?? false)) return;
    final staff = NewStaff(
      username: _username.text,
      displayName: _name.text,
      password: _password.text,
      permissions: {..._selected},
    );
    try {
      await ref.read(adminActionsProvider).createStaff(staff);
      if (!mounted) return;
      AppFeedback.show(context, l10n.staffCreated(staff.displayName.trim()));
      setState(() => _dirty = false);
      final nav = ref.read(appNavigatorProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) => nav.back());
    } on AppFailure catch (f) {
      if (!mounted) return;
      if (f.kind == FailureKind.alreadyExists) {
        setState(() => _usernameError = l10n.staffUsernameTaken);
      } else {
        AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return OwnerOnly(
      child: UnsavedChangesGuard(
        hasUnsavedChanges: _dirty,
        child: Scaffold(
          appBar: AppBar(title: Text(l10n.staffNewTitle)),
          body: Form(
            key: _form,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
                child: // Not a lazy ListView: every field must stay mounted so Form.validate()
                    // checks the ones scrolled off-screen too.
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.gutter),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _name,
                            decoration: InputDecoration(labelText: l10n.fieldPersonName),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            maxLength: 80,
                            validator: (v) => (v ?? '').trim().isEmpty ? l10n.validationRequired : null,
                          ),
                          TextFormField(
                            controller: _username,
                            decoration: InputDecoration(
                              labelText: l10n.loginUsername,
                              helperText: l10n.staffUsernameHint,
                              helperMaxLines: 2,
                              errorText: _usernameError,
                              prefixText: '@',
                            ),
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              LengthLimitingTextInputFormatter(32),
                            ],
                            validator: (v) => switch (Username.validate(v ?? '')) {
                              UsernameIssue.empty => l10n.validationUsernameRequired,
                              UsernameIssue.invalid => l10n.validationUsernameInvalid,
                              null => null,
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          PasswordField(
                            controller: _password,
                            label: l10n.loginPassword,
                            helperText: l10n.staffPasswordHint,
                            username: () => _username.text,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(l10n.staffPermissions, style: text.titleMedium),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(l10n.staffPermissionsHint, style: text.bodySmall),
                          for (final p in Permission.values)
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _selected.contains(p),
                              title: Text(permissionLabel(l10n, p)),
                              onChanged: (v) => setState(() {
                                v == true ? _selected.add(p) : _selected.remove(p);
                                _dirty = true;
                              }),
                            ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(label: l10n.staffCreate, icon: Icons.person_add_alt_1_rounded, onPressed: _create),
                          const SizedBox(height: AppSpacing.huge),
                        ],
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
