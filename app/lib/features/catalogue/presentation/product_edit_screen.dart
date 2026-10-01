import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../application/catalogue_providers.dart';
import '../domain/catalogue.dart';

/// Create or edit a design. Photos can be added once the design exists.
class ProductEditScreen extends ConsumerStatefulWidget {
  const ProductEditScreen({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends ConsumerState<ProductEditScreen> {
  final _form = GlobalKey<FormState>();
  final _designNo = TextEditingController();
  final _name = TextEditingController();
  final _rate = TextEditingController();
  final _weight = TextEditingController();
  final _description = TextEditingController();
  final _cost = TextEditingController();
  final _supplier = TextEditingController();
  final _note = TextEditingController();
  String? _categoryId;
  bool _available = true;
  bool _dirty = false;
  bool _loaded = false;
  String? _productId;
  Money? _originalRate;
  String? _designNoError;

  @override
  void initState() {
    super.initState();
    _productId = widget.productId;
    for (final c in [_designNo, _name, _rate, _weight, _description, _cost, _supplier, _note]) {
      c.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (_loaded && !_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    for (final c in [_designNo, _name, _rate, _weight, _description, _cost, _supplier, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(ProductDetail p) {
    _designNo.text = p.designNo;
    _name.text = p.name;
    _rate.text = p.rate.format(symbol: false).replaceAll(',', '');
    _weight.text = p.weightMg == null ? '' : AppFormat.gramsInput(p.weightMg!);
    _description.text = p.description ?? '';
    _cost.text = p.private?.cost?.format(symbol: false).replaceAll(',', '') ?? '';
    _supplier.text = p.private?.supplierName ?? '';
    _note.text = p.private?.internalNote ?? '';
    _categoryId = p.categoryId;
    _available = p.isAvailable;
    _originalRate = p.rate;
  }

  ProductDraft _draft() => ProductDraft(
    designNo: _designNo.text,
    name: _name.text,
    rate: Money.tryParseRupees(_rate.text),
    description: _description.text,
    categoryId: _categoryId,
    weightMg: _weight.text.trim().isEmpty ? null : AppFormat.parseGramsToMg(_weight.text),
    isAvailable: _available,
    cost: _cost.text.trim().isEmpty ? null : Money.tryParseRupees(_cost.text),
    supplierName: _supplier.text,
    internalNote: _note.text,
  );

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _designNoError = null);
    if (!(_form.currentState?.validate() ?? false)) return;
    final draft = _draft();
    final editor = ref.read(productEditorProvider);
    try {
      if (_productId == null) {
        final id = await editor.create(draft);
        if (!mounted) return;
        setState(() {
          _productId = id;
          _originalRate = draft.rate;
          _dirty = false;
        });
      } else {
        await editor.update(_productId!, draft, rateChanged: draft.rate != _originalRate);
        if (!mounted) return;
        setState(() {
          _originalRate = draft.rate;
          _dirty = false;
        });
      }
      if (mounted) AppFeedback.show(context, l10n.commonSaved);
    } on AppFailure catch (f) {
      if (!mounted) return;
      if (f.kind == FailureKind.alreadyExists) {
        setState(() => _designNoError = l10n.designNoTaken);
      } else {
        AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
      }
    }
  }

  Future<void> _toggleArchive(ProductDetail p) async {
    final l10n = AppLocalizations.of(context);
    final archive = !p.isArchived;
    if (archive) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.archiveDesign),
          content: Text(l10n.archiveDesignBody(p.designNo)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonCancel)),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.archiveDesign)),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      await ref.read(productEditorProvider).setArchived(p.id, archived: archive);
      if (mounted) AppFeedback.show(context, l10n.commonSaved);
    } on AppFailure catch (f) {
      if (mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    }
  }

  Future<void> _newCategory() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.categoryNew),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: InputDecoration(labelText: l10n.fieldName),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: Text(l10n.commonAdd)),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    try {
      final category = await ref.read(productEditorProvider).createCategory(name);
      if (mounted) {
        setState(() {
          _categoryId = category.id;
          _dirty = true;
        });
      }
    } on AppFailure catch (f) {
      if (mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(currentSessionProvider);
    final isOwner = session?.isOwner ?? false;
    final canRate = session?.can(Permission.ratesManage) ?? false;
    final id = _productId;

    if (id != null && !_loaded) {
      final detail = ref.watch(productDetailProvider(id));
      switch (detail) {
        case AsyncData(:final value?):
          _fill(value);
          _loaded = true;
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
              onRetry: () => ref.refresh(productDetailProvider(id).future),
            ),
          );
        default:
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
      }
    } else if (id == null) {
      _loaded = true;
    }

    final detail = id == null ? null : ref.watch(productDetailProvider(id)).value;
    final rateLocked = id != null && !canRate;
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];

    String? validateRate(String? v) => (Money.tryParseRupees(v ?? '')?.paise ?? 0) <= 0 ? l10n.validationAmount : null;

    return UnsavedChangesGuard(
      hasUnsavedChanges: _dirty,
      child: Scaffold(
        appBar: AppBar(title: Text(id == null ? l10n.productAdd : l10n.productEdit)),
        body: Form(
          key: _form,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  TextFormField(
                    controller: _designNo,
                    decoration: InputDecoration(labelText: l10n.fieldDesignNo, errorText: _designNoError),
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return l10n.validationRequired;
                      if (!ProductDraft.designNoPattern.hasMatch(value)) return l10n.validationDesignNo;
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(labelText: l10n.fieldName),
                    textInputAction: TextInputAction.next,
                    maxLength: 120,
                    validator: (v) => (v ?? '').trim().isEmpty ? l10n.validationRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _rate,
                          enabled: !rateLocked,
                          decoration: InputDecoration(
                            labelText: l10n.fieldRate,
                            prefixText: '₹ ',
                            helperText: rateLocked ? l10n.rateNeedsPermission : null,
                            helperMaxLines: 2,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          validator: rateLocked ? null : validateRate,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _weight,
                          decoration: InputDecoration(labelText: l10n.fieldWeight),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          validator: (v) => (v ?? '').trim().isEmpty || AppFormat.parseGramsToMg(v!) != null
                              ? null
                              : l10n.validationWeight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                          decoration: InputDecoration(labelText: l10n.fieldCategory),
                          items: [
                            DropdownMenuItem(value: null, child: Text(l10n.fieldNoCategory)),
                            for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
                          ],
                          onChanged: (v) => setState(() {
                            _categoryId = v;
                            _dirty = true;
                          }),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.categoryNew,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        onPressed: _newCategory,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _description,
                    decoration: InputDecoration(labelText: l10n.fieldDescription),
                    maxLines: 3,
                    maxLength: 1000,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.fieldAvailable),
                    value: _available,
                    onChanged: (v) => setState(() {
                      _available = v;
                      _dirty = true;
                    }),
                  ),
                  if (isOwner) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.goldText),
                        const SizedBox(width: AppSpacing.xs),
                        Text(l10n.ownerOnlySection, style: AppType.label.copyWith(color: AppColors.goldText)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _cost,
                      decoration: InputDecoration(labelText: l10n.fieldCost, prefixText: '₹ '),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                      validator: (v) =>
                          (v ?? '').trim().isEmpty || Money.tryParseRupees(v!) != null ? null : l10n.validationAmount,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _supplier,
                      decoration: InputDecoration(labelText: l10n.fieldSupplier),
                      maxLength: 120,
                    ),
                    TextFormField(
                      controller: _note,
                      decoration: InputDecoration(labelText: l10n.fieldInternalNote),
                      maxLines: 2,
                      maxLength: 1000,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppButton(label: l10n.commonSave, icon: Icons.check_rounded, confirmSuccess: true, onPressed: _save),
                  const SizedBox(height: AppSpacing.xl),
                  _PhotosEditor(productId: id, photos: detail?.photos ?? const []),
                  if (detail != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: detail.isArchived ? l10n.unarchiveDesign : l10n.archiveDesign,
                      icon: detail.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                      variant: AppButtonVariant.quiet,
                      onPressed: () => _toggleArchive(detail),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.huge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotosEditor extends ConsumerStatefulWidget {
  const _PhotosEditor({required this.productId, required this.photos});

  final String? productId;
  final List<ProductPhoto> photos;

  @override
  ConsumerState<_PhotosEditor> createState() => _PhotosEditorState();
}

class _PhotosEditorState extends ConsumerState<_PhotosEditor> {
  bool _busy = false;

  Future<void> _add(PhotoOrigin origin) async {
    final l10n = AppLocalizations.of(context);
    final id = widget.productId;
    if (id == null || _busy) return;
    try {
      final bytes = await ref.read(photoPickerProvider).pick(origin);
      if (bytes == null) return;
      setState(() => _busy = true);
      await ref.read(productEditorProvider).addPhoto(id, bytes, sortOrder: widget.photos.length);
      if (mounted) AppFeedback.show(context, l10n.photoAdded);
    } on ImageRejectedException catch (e) {
      if (mounted) {
        AppFeedback.show(
          context,
          e.reason == ImageRejection.tooLarge ? l10n.photoTooLarge : l10n.photoRejected,
          tone: FeedbackTone.error,
        );
      }
    } on AppFailure catch (f) {
      if (mounted) {
        AppFeedback.show(
          context,
          f.kind == FailureKind.alreadyExists ? l10n.photoDuplicate : f.message(l10n),
          tone: FeedbackTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(ProductPhoto photo) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(productEditorProvider).removePhoto(widget.productId!, photo.id);
    } on AppFailure catch (f) {
      if (mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    if (widget.productId == null) {
      return Text(l10n.photoSaveFirst, style: text.bodyMedium!.copyWith(color: AppColors.muted));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.photosTitle, style: text.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final photo in widget.photos)
              SizedBox.square(
                dimension: 96,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.control,
                      child: RemoteImage(path: photo.thumbPath, decodeWidth: 96),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: IconButton.filledTonal(
                        tooltip: l10n.commonRemove,
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _remove(photo),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            if (_busy)
              SizedBox.square(
                dimension: 96,
                child: Semantics(
                  label: l10n.photoPreparing,
                  liveRegion: true,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: AppRadius.control),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: l10n.photoCamera,
                icon: Icons.photo_camera_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: _busy ? null : () => _add(PhotoOrigin.camera),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: l10n.photoGallery,
                icon: Icons.photo_library_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: _busy ? null : () => _add(PhotoOrigin.gallery),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
