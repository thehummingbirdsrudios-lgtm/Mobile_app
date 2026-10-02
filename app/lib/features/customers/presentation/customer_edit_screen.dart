import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../application/customer_providers.dart';
import '../domain/customers.dart';

/// Add or edit a customer. Only the name is required; everything else can
/// be filled in later.
class CustomerEditScreen extends ConsumerStatefulWidget {
  const CustomerEditScreen({super.key, this.customerId});

  final String? customerId;

  @override
  ConsumerState<CustomerEditScreen> createState() => _CustomerEditScreenState();
}

class _CustomerEditScreenState extends ConsumerState<CustomerEditScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _shop = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _notes = TextEditingController();
  final _opening = TextEditingController();
  // One id per form: a retried save can never post the opening Baki twice.
  final _openingRequestId = newUuid();
  bool _sameWhatsapp = true;
  bool _loaded = false;
  bool _dirty = false;

  List<TextEditingController> get _all => [_name, _shop, _city, _phone, _whatsapp, _notes, _opening];

  @override
  void initState() {
    super.initState();
    for (final c in _all) {
      c.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (_loaded && !_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(CustomerDetail c) {
    _name.text = c.name;
    _shop.text = c.shopName ?? '';
    _city.text = c.city ?? '';
    _phone.text = c.phone ?? '';
    _whatsapp.text = c.whatsappPhone ?? '';
    _notes.text = c.notes ?? '';
    _sameWhatsapp = c.whatsappPhone == null || c.whatsappPhone == c.phone;
  }

  CustomerDraft _draft() => CustomerDraft(
    name: _name.text,
    shopName: _shop.text,
    city: _city.text,
    phone: _phone.text,
    whatsappPhone: _sameWhatsapp ? '' : _whatsapp.text,
    notes: _notes.text,
  );

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!(_form.currentState?.validate() ?? false)) return;
    final editor = ref.read(customerEditorProvider);
    final nav = ref.read(appNavigatorProvider);
    try {
      final id = widget.customerId;
      if (id == null) {
        final opening = _opening.text.trim().isEmpty ? null : Money.tryParseRupees(_opening.text);
        final result = await editor.create(_draft(), openingBaki: opening, openingRequestId: _openingRequestId);
        if (!mounted) return;
        if (result.opening == OpeningBakiResult.failed) {
          AppFeedback.show(context, l10n.openingBakiFailed, tone: FeedbackTone.warning);
        } else {
          AppFeedback.show(context, l10n.commonSaved);
        }
        _leave(() {
          nav
            ..back()
            ..openCustomer(result.id);
        });
      } else {
        await editor.update(id, _draft());
        if (!mounted) return;
        AppFeedback.show(context, l10n.commonSaved);
        _leave(nav.back);
      }
    } on AppFailure catch (f) {
      if (mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    }
  }

  /// Clears the unsaved-changes guard, then navigates once it has rebuilt.
  void _leave(VoidCallback navigate) {
    setState(() => _dirty = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => navigate());
  }

  Future<void> _toggleArchive(CustomerDetail c) async {
    final l10n = AppLocalizations.of(context);
    final archive = !c.isArchived;
    if (archive) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.archiveCustomer),
          content: Text(l10n.archiveCustomerBody(c.name)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonCancel)),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.archiveCustomer)),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      await ref.read(customerEditorProvider).setArchived(c.id, archived: archive);
      if (mounted) AppFeedback.show(context, l10n.commonSaved);
    } on AppFailure catch (f) {
      if (mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(currentSessionProvider);
    final id = widget.customerId;
    CustomerDetail? existing;

    if (id != null) {
      final detail = ref.watch(customerDetailProvider(id));
      switch (detail) {
        case AsyncData(:final value?):
          existing = value;
          if (!_loaded) {
            _fill(value);
            _loaded = true;
          }
        case AsyncData():
          return Scaffold(
            appBar: AppBar(),
            body: EmptyState(icon: Icons.search_off_rounded, title: l10n.commonNotFound),
          );
        case AsyncError(:final error):
          return Scaffold(
            appBar: AppBar(),
            body: ErrorState(
              failure: AppFailure.from(error),
              onRetry: () => ref.refresh(customerDetailProvider(id).future),
            ),
          );
        default:
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
      }
    } else {
      _loaded = true;
    }
    final canOpening = id == null && (session?.can(Permission.hisaabAdjust) ?? false);

    String? phoneValidator(String? v) =>
        CustomerDraft.isValidPhone(CustomerDraft.normalisePhone(v ?? '')) ? null : l10n.validationPhone;
    final digits = [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-]'))];

    return UnsavedChangesGuard(
      hasUnsavedChanges: _dirty,
      child: Scaffold(
        appBar: AppBar(title: Text(id == null ? l10n.customerAdd : l10n.customerEdit)),
        body: Form(
          key: _form,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
              // Not a lazy ListView: every field must stay mounted so Form.validate()
              // also checks fields scrolled off-screen.
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: InputDecoration(labelText: l10n.fieldCustomerName),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      maxLength: 120,
                      validator: (v) => (v ?? '').trim().isEmpty ? l10n.validationRequired : null,
                    ),
                    TextFormField(
                      controller: _shop,
                      decoration: InputDecoration(labelText: l10n.fieldShopName),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      maxLength: 120,
                    ),
                    TextFormField(
                      controller: _city,
                      decoration: InputDecoration(labelText: l10n.fieldCity),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      maxLength: 60,
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
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.whatsappSameAsMobile),
                      value: _sameWhatsapp,
                      onChanged: (v) => setState(() {
                        _sameWhatsapp = v;
                        _dirty = true;
                      }),
                    ),
                    if (!_sameWhatsapp)
                      TextFormField(
                        controller: _whatsapp,
                        decoration: InputDecoration(
                          labelText: l10n.fieldWhatsapp,
                          prefixIcon: const Icon(Icons.chat_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: digits,
                        validator: phoneValidator,
                      ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _notes,
                      decoration: InputDecoration(labelText: l10n.fieldNotes),
                      maxLines: 3,
                      maxLength: 1000,
                    ),
                    if (canOpening) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _opening,
                        decoration: InputDecoration(
                          labelText: l10n.fieldOpeningBaki,
                          prefixText: '₹ ',
                          helperText: l10n.openingBakiHelp,
                          helperMaxLines: 2,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                        validator: (v) => (v ?? '').trim().isEmpty || (Money.tryParseRupees(v!)?.paise ?? 0) > 0
                            ? null
                            : l10n.validationAmount,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(label: l10n.commonSave, icon: Icons.check_rounded, onPressed: _save),
                    if (existing != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: existing.isArchived ? l10n.unarchiveCustomer : l10n.archiveCustomer,
                        icon: existing.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                        variant: AppButtonVariant.quiet,
                        onPressed: () => unawaited(_toggleArchive(existing!)),
                      ),
                    ],
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
