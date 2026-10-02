import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../application/admin_providers.dart';
import '../domain/admin.dart';
import 'admin_labels.dart';

/// The owner's business details: what bills, receipts and shares print.
class BusinessProfileScreen extends StatelessWidget {
  const BusinessProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const OwnerOnly(child: _ProfileLoader());
}

class _ProfileLoader extends ConsumerWidget {
  const _ProfileLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(businessProfileProvider);
    // Reloads (after a save or a logo change) keep the form and its unsaved
    // edits on screen: only the very first load shows progress.
    return switch (profile) {
      AsyncValue(:final value?) => _ProfileForm(profile: value),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(title: Text(l10n.adminBusinessProfile)),
        body: ErrorState(failure: AppFailure.from(error), onRetry: () => ref.refresh(businessProfileProvider.future)),
      ),
      _ => Scaffold(
        appBar: AppBar(title: Text(l10n.adminBusinessProfile)),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.profile});

  final BusinessProfile profile;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.businessName);
  late final _phone = TextEditingController(text: widget.profile.phone ?? '');
  late final _whatsapp = TextEditingController(text: widget.profile.whatsappPhone ?? '');
  late final _address = TextEditingController(text: widget.profile.address ?? '');
  late final _gstin = TextEditingController(text: widget.profile.gstin ?? '');
  late final _footer = TextEditingController(text: widget.profile.billFooter ?? '');
  late bool _watermark = widget.profile.watermarkEnabled;
  late String _locale = widget.profile.defaultLocale;
  bool _dirty = false;
  bool _logoBusy = false;

  List<TextEditingController> get _all => [_name, _phone, _whatsapp, _address, _gstin, _footer];

  static const _languageNames = {'gu': 'ગુજરાતી', 'hi': 'हिन्दी', 'en': 'English'};

  @override
  void initState() {
    super.initState();
    for (final c in _all) {
      c.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  BusinessProfileDraft _draft() => BusinessProfileDraft(
    businessName: _name.text,
    phone: _phone.text,
    whatsappPhone: _whatsapp.text,
    address: _address.text,
    gstin: _gstin.text,
    billFooter: _footer.text,
    watermarkEnabled: _watermark,
    defaultLocale: _locale,
  );

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!(_form.currentState?.validate() ?? false)) return;
    try {
      await ref.read(adminActionsProvider).saveProfile(_draft());
      if (!mounted) return;
      setState(() => _dirty = false);
      AppFeedback.show(context, l10n.commonSaved);
    } on AppFailure catch (f) {
      if (mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    }
  }

  Future<void> _changeLogo() async {
    final l10n = AppLocalizations.of(context);
    try {
      final bytes = await ref.read(photoPickerProvider).pick(PhotoOrigin.gallery);
      if (bytes == null || !mounted) return;
      setState(() => _logoBusy = true);
      await ref.read(adminActionsProvider).replaceLogo(bytes);
      if (mounted) AppFeedback.show(context, l10n.profileLogoSaved);
    } on ImageRejectedException catch (e) {
      if (mounted) {
        AppFeedback.show(
          context,
          e.reason == ImageRejection.tooLarge ? l10n.photoTooLarge : l10n.photoRejected,
          tone: FeedbackTone.error,
        );
      }
    } on AppFailure catch (f) {
      if (mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    } finally {
      if (mounted) setState(() => _logoBusy = false);
    }
  }

  Future<void> _removeLogo() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _logoBusy = true);
    try {
      await ref.read(adminActionsProvider).removeLogo();
      if (mounted) AppFeedback.show(context, l10n.profileLogoRemoved);
    } on AppFailure catch (f) {
      if (mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    } finally {
      if (mounted) setState(() => _logoBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    // The logo is saved on its own (no Save needed); read it live.
    final logoPath = ref.watch(businessProfileProvider).value?.logoPath ?? widget.profile.logoPath;
    final digits = [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-]'))];
    String? phoneValidator(String? v) =>
        PhoneNumbers.isValid(PhoneNumbers.normalise(v ?? '')) ? null : l10n.validationPhone;

    return UnsavedChangesGuard(
      hasUnsavedChanges: _dirty,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.adminBusinessProfile)),
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
                        AppCard(
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                child: SizedBox.square(
                                  dimension: 72,
                                  child: logoPath == null
                                      ? const ColoredBox(
                                          color: AppColors.surfaceMuted,
                                          child: Icon(Icons.storefront_outlined, color: AppColors.muted),
                                        )
                                      : RemoteImage(
                                          path: logoPath,
                                          bucket: Buckets.branding,
                                          fit: BoxFit.contain,
                                          decodeWidth: 72,
                                          semanticLabel: l10n.profileLogo,
                                        ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.profileLogo, style: text.titleMedium),
                                    Text(l10n.profileLogoHint, style: text.bodySmall),
                                    const SizedBox(height: AppSpacing.xs),
                                    Wrap(
                                      spacing: AppSpacing.xs,
                                      children: [
                                        TextButton.icon(
                                          onPressed: _logoBusy ? null : () => unawaited(_changeLogo()),
                                          icon: _logoBusy
                                              ? const SizedBox.square(
                                                  dimension: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Icon(Icons.image_outlined),
                                          label: Text(logoPath == null ? l10n.profileLogoAdd : l10n.profileLogoChange),
                                        ),
                                        if (logoPath != null)
                                          TextButton(
                                            onPressed: _logoBusy ? null : () => unawaited(_removeLogo()),
                                            child: Text(l10n.profileLogoRemove),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          controller: _name,
                          decoration: InputDecoration(labelText: l10n.fieldBusinessName),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          maxLength: 120,
                          validator: (v) => (v ?? '').trim().isEmpty ? l10n.validationRequired : null,
                        ),
                        TextFormField(
                          controller: _phone,
                          decoration: InputDecoration(
                            labelText: l10n.fieldMobile,
                            prefixIcon: const Icon(Icons.call_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          inputFormatters: digits,
                          textInputAction: TextInputAction.next,
                          validator: phoneValidator,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _whatsapp,
                          decoration: InputDecoration(
                            labelText: l10n.fieldWhatsapp,
                            prefixIcon: const Icon(Icons.chat_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          inputFormatters: digits,
                          textInputAction: TextInputAction.next,
                          validator: phoneValidator,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _address,
                          decoration: InputDecoration(labelText: l10n.fieldAddress),
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 3,
                          minLines: 2,
                          maxLength: 400,
                        ),
                        TextFormField(
                          controller: _gstin,
                          decoration: InputDecoration(labelText: l10n.fieldGstin),
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9A-Za-z ]'))],
                          validator: (v) => BusinessProfileDraft.isValidGstin(v ?? '') ? null : l10n.validationGstin,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _footer,
                          decoration: InputDecoration(labelText: l10n.fieldBillFooter),
                          maxLines: 3,
                          minLines: 2,
                          maxLength: 400,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.profileWatermark),
                          subtitle: Text(l10n.profileWatermarkHint),
                          value: _watermark,
                          onChanged: (v) => setState(() {
                            _watermark = v;
                            _dirty = true;
                          }),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(l10n.profileDefaultLanguage, style: text.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        SegmentedButton<String>(
                          segments: [
                            for (final code in const ['gu', 'hi', 'en'])
                              ButtonSegment(value: code, label: Text(_languageNames[code]!)),
                          ],
                          selected: {_locale},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) => setState(() {
                            _locale = s.single;
                            _dirty = true;
                          }),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(label: l10n.commonSave, icon: Icons.check_rounded, onPressed: _save),
                        const SizedBox(height: AppSpacing.huge),
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
