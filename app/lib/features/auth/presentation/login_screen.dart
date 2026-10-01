import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../application/session_controller.dart';
import '../domain/auth_repository.dart';

/// Brand → Namaskar → Username → Password → Login. Nothing else competes.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  AppFailure? _failure;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _failure = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    try {
      await ref.read(sessionControllerProvider.notifier).signIn(username: _username.text, password: _password.text);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final config = ref.watch(appConfigProvider);
    final session = ref.watch(sessionControllerProvider);
    final shownFailure = _failure ?? (session is SessionSignedOut ? session.reason : null);

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: BrandMark(size: 64)),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(l10n.loginGreeting, style: text.displaySmall),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(l10n.loginSubtitle, style: text.bodyLarge!.copyWith(color: AppColors.muted)),
                        const SizedBox(height: AppSpacing.xxl),
                        if (!config.isConfigured) ...[
                          _Banner(title: l10n.notConfiguredTitle, body: l10n.notConfiguredBody),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        TextFormField(
                          controller: _username,
                          decoration: InputDecoration(labelText: l10n.loginUsername),
                          autofillHints: const [AutofillHints.username],
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.visiblePassword,
                          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                          validator: (value) => switch (Username.validate(value ?? '')) {
                            UsernameIssue.empty => l10n.validationUsernameRequired,
                            UsernameIssue.invalid => l10n.validationUsernameInvalid,
                            null => null,
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _password,
                          focusNode: _passwordFocus,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: l10n.loginPassword,
                            suffixIcon: IconButton(
                              tooltip: _obscure ? l10n.loginShowPassword : l10n.loginHidePassword,
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (value) => (value ?? '').isEmpty ? l10n.validationPasswordRequired : null,
                        ),
                        AnimatedSize(
                          duration: AppMotion.of(context, AppMotion.quick),
                          child: shownFailure == null
                              ? const SizedBox(height: AppSpacing.xl)
                              : Padding(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  child: Semantics(
                                    liveRegion: true,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                                        const SizedBox(width: AppSpacing.xs),
                                        Expanded(
                                          child: Text(
                                            shownFailure.message(l10n),
                                            style: text.bodyMedium!.copyWith(color: AppColors.error),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                        AppButton(label: l10n.loginButton, onPressed: _submit),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.loginNoAccountHint,
                          style: text.bodyMedium!.copyWith(color: AppColors.muted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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

class _Banner extends StatelessWidget {
  const _Banner({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(color: AppColors.warningTint, borderRadius: AppRadius.control),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium!.copyWith(color: AppColors.warning)),
                Text(body, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
