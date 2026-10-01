import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../../customers/customers.dart';
import '../application/cart_controller.dart';
import '../domain/orders.dart';
import 'customer_picker.dart';

/// Build and place an order: customer, designs (from Maal, Regular Maal or
/// typed design numbers), quantities, optional payment, one button.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key, this.customerId, this.quickEntry = false});

  /// Pre-selects this customer (e.g. "Order Karo" on a customer).
  final String? customerId;

  /// Opens with the design-number field focused (Quick order).
  final bool quickEntry;

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _designNo = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _designFocus = FocusNode();
  final _note = TextEditingController();
  final _payAmount = TextEditingController();
  final _payReference = TextEditingController();
  bool _takePayment = false;
  PaymentMode _payMode = PaymentMode.cash;
  String? _quickError;

  @override
  void initState() {
    super.initState();
    _note.text = ref.read(cartProvider).note;
    if (widget.customerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _preselect(widget.customerId!));
    }
  }

  @override
  void dispose() {
    for (final c in [_designNo, _qty, _note, _payAmount, _payReference]) {
      c.dispose();
    }
    _designFocus.dispose();
    super.dispose();
  }

  CartController get _cart => ref.read(cartProvider.notifier);

  Future<void> _preselect(String customerId) async {
    final l10n = AppLocalizations.of(context);
    final draft = ref.read(cartProvider);
    if (draft.customerId == customerId) return;
    try {
      final customer = await ref.read(customerDetailProvider(customerId).future);
      if (customer == null || !mounted) return;
      if (draft.customerId != null && !draft.isEmpty) {
        final startNew = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.cartOtherCustomerTitle),
            content: Text(l10n.cartOtherCustomerBody(draft.customerName ?? '', draft.lines.length)),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cartKeepOld)),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.cartStartNew)),
            ],
          ),
        );
        if (startNew != true) return;
        _cart.reset(customerId: customer.id, customerName: customer.name);
        _note.clear();
      } else {
        await _cart.selectCustomer(customer.id, customer.name);
      }
    } on AppFailure catch (f) {
      if (mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    }
  }

  Future<void> _pickCustomer() async {
    final l10n = AppLocalizations.of(context);
    final picked = await showCustomerPicker(context);
    if (picked == null) return;
    try {
      await _cart.selectCustomer(picked.id, picked.name);
    } on AppFailure catch (f) {
      if (mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    }
  }

  Future<void> _quickAdd() async {
    final l10n = AppLocalizations.of(context);
    final designNo = _designNo.text.trim();
    final qty = int.tryParse(_qty.text.trim()) ?? 0;
    if (designNo.isEmpty) return;
    if (qty < 1 || qty > OrderLimits.maxQty) {
      setState(() => _quickError = l10n.validationRequired);
      return;
    }
    try {
      final q = await _cart.addDesignNo(designNo, qty: qty);
      if (!mounted) return;
      if (q == null) {
        setState(() => _quickError = l10n.quickAddNotFound(designNo));
      } else if (!q.isOrderable) {
        setState(() => _quickError = l10n.quickAddUnavailable(q.designNo));
      } else {
        setState(() => _quickError = null);
        _designNo.clear();
        _qty.text = '1';
        AppFeedback.show(context, l10n.quickAddAdded(q.designNo));
      }
      _designFocus.requestFocus();
    } on AppFailure catch (f) {
      if (mounted) setState(() => _quickError = f.message(l10n));
    }
  }

  Future<void> _editQty(CartLine line) async {
    final l10n = AppLocalizations.of(context);
    final value = await showTextInputDialog(
      context,
      title: '${line.designNo} · ${line.name}',
      label: l10n.quickAddQty,
      confirmLabel: l10n.commonDone,
      initialValue: '${line.qty}',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
      requireValue: true,
    );
    final qty = int.tryParse(value ?? '');
    if (qty != null && qty > 0 && mounted) _cart.setQty(line.productId, qty);
  }

  PaymentInput? _payment(CartDraft draft) {
    if (!_takePayment) return null;
    final amount = Money.tryParseRupees(_payAmount.text);
    if (amount == null || amount.paise <= 0) return null;
    return PaymentInput(amount: amount, mode: _payMode, reference: _payReference.text);
  }

  Future<void> _place() async {
    final l10n = AppLocalizations.of(context);
    final draft = ref.read(cartProvider);
    if (draft.customerId == null) {
      AppFeedback.show(context, l10n.cartNeedsCustomer, tone: FeedbackTone.warning);
      unawaited(_pickCustomer());
      return;
    }
    if (_takePayment && _payment(draft) == null) {
      AppFeedback.show(context, l10n.validationAmount, tone: FeedbackTone.error);
      return;
    }
    if (_note.text != draft.note) _cart.setNote(_note.text);
    try {
      final placed = await _cart.place(payment: _payment(draft));
      if (!mounted) return;
      _note.clear();
      _payAmount.clear();
      _payReference.clear();
      setState(() => _takePayment = false);
      // The button stops being busy as soon as the server has answered.
      unawaited(_showPlaced(placed));
    } on CartException catch (e) {
      if (!mounted) return;
      AppFeedback.show(context, switch (e.problem) {
        CartProblem.noCustomer => l10n.cartNeedsCustomer,
        CartProblem.empty => l10n.cartEmpty,
        CartProblem.unavailable => l10n.unavailableInCart,
      }, tone: FeedbackTone.warning);
    } on AppFailure catch (f) {
      if (!mounted) return;
      switch (f.kind) {
        case FailureKind.rateChanged:
          unawaited(
            showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.ratesChangedTitle),
                content: Text(l10n.ratesChangedBody),
                actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonDone))],
              ),
            ),
          );
        case FailureKind.productUnavailable:
          AppFeedback.show(context, l10n.unavailableInCart, tone: FeedbackTone.warning);
        default:
          AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
      }
    }
  }

  Future<void> _showPlaced(PlacedOrder placed) async {
    final l10n = AppLocalizations.of(context);
    final nav = ref.read(appNavigatorProvider);
    final viewOrder = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final text = Theme.of(context).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: SuccessCheck(color: AppColors.success, size: 64)),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.orderPlacedTitle('${placed.orderNo}'), style: text.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${placed.total.format()} · ${l10n.piecesCount(placed.totalQty)}',
                  style: text.bodyLarge!.copyWith(fontFeatures: AppType.figures),
                  textAlign: TextAlign.center,
                ),
                if (placed.replayed) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.orderAlreadyPlaced,
                    style: text.bodyMedium!.copyWith(color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(label: l10n.viewOrder, onPressed: () => Navigator.of(context).pop(true)),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.orderNew,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (viewOrder ?? false) {
      nav
        ..back()
        ..openOrder(placed.orderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final draft = ref.watch(cartProvider);
    final session = ref.watch(currentSessionProvider);
    final canPay = session?.can(Permission.paymentsRecord) ?? false;
    final weight = draft.totalWeightMg;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quickEntry ? l10n.quickOrder : l10n.orderNew),
        actions: [
          if (!draft.isEmpty)
            IconButton(
              tooltip: l10n.cartClear,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () {
                _cart.reset(customerId: draft.customerId, customerName: draft.customerName);
                _note.clear();
              },
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        l10n.piecesCount(draft.totalQty),
                        if (weight != null && weight > 0) AppFormat.grams(weight),
                      ].join(' · '),
                      style: text.bodyMedium!.copyWith(color: AppColors.muted, fontFeatures: AppType.figures),
                    ),
                  ),
                  Text('${l10n.cartTotal} ', style: text.bodyMedium!.copyWith(color: AppColors.muted)),
                  MoneyText(draft.total, style: text.titleLarge),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                label: l10n.placeOrder,
                icon: Icons.check_rounded,
                onPressed: draft.isEmpty || draft.hasUnavailable ? null : _place,
              ),
            ],
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: [
              _CustomerBar(draft: draft, onPick: () => unawaited(_pickCustomer())),
              const SizedBox(height: AppSpacing.md),
              _QuickAdd(
                designNo: _designNo,
                qty: _qty,
                focus: _designFocus,
                autofocus: widget.quickEntry,
                error: _quickError,
                onAdd: _quickAdd,
              ),
              const SizedBox(height: AppSpacing.md),
              if (draft.customerId != null) _RegularSuggestions(customerId: draft.customerId!, draft: draft),
              if (draft.hasUnavailable)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(l10n.unavailableInCart, style: text.bodyMedium!.copyWith(color: AppColors.error)),
                ),
              if (draft.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Text(
                    l10n.cartEmpty,
                    textAlign: TextAlign.center,
                    style: text.bodyLarge!.copyWith(color: AppColors.muted),
                  ),
                )
              else
                for (final line in draft.lines)
                  _LineTile(
                    key: ValueKey(line.productId),
                    line: line,
                    onQty: (q) => _cart.setQty(line.productId, q),
                    onEditQty: () => _editQty(line),
                    onRemove: () => _cart.remove(line.productId),
                  ),
              if (!draft.isEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _note,
                  maxLength: OrderLimits.maxNote,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l10n.fieldOrderNote),
                  onChanged: _cart.setNote,
                ),
                if (canPay) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.paymentNow),
                    value: _takePayment,
                    onChanged: (v) => setState(() {
                      _takePayment = v;
                      if (v && _payAmount.text.isEmpty) {
                        _payAmount.text = draft.total.format(symbol: false).replaceAll(',', '');
                      }
                    }),
                  ),
                  if (_takePayment)
                    _PaymentFields(
                      amount: _payAmount,
                      reference: _payReference,
                      mode: _payMode,
                      onMode: (m) => setState(() => _payMode = m),
                    ),
                ],
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerBar extends StatelessWidget {
  const _CustomerBar({required this.draft, required this.onPick});

  final CartDraft draft;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    if (draft.customerId == null) {
      return AppButton(
        label: l10n.cartChooseCustomer,
        icon: Icons.person_search_rounded,
        variant: AppButtonVariant.secondary,
        onPressed: onPick,
      );
    }
    return AppCard(
      onTap: onPick,
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined, color: AppColors.goldText),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(draft.customerName ?? '', style: text.titleMedium)),
          Text(l10n.cartChangeCustomer, style: text.labelLarge!.copyWith(color: AppColors.goldText)),
        ],
      ),
    );
  }
}

class _QuickAdd extends StatelessWidget {
  const _QuickAdd({
    required this.designNo,
    required this.qty,
    required this.focus,
    required this.autofocus,
    required this.onAdd,
    this.error,
  });

  final TextEditingController designNo;
  final TextEditingController qty;
  final FocusNode focus;
  final bool autofocus;
  final String? error;
  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: designNo,
            focusNode: focus,
            autofocus: autofocus,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.fieldDesignNo, errorText: error, errorMaxLines: 2),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: TextField(
            controller: qty,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            decoration: InputDecoration(labelText: l10n.quickAddQty),
            onSubmitted: (_) => unawaited(onAdd()),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: IconButton.filled(
            tooltip: l10n.commonAdd,
            iconSize: 28,
            style: IconButton.styleFrom(minimumSize: const Size.square(52)),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }
}

class _RegularSuggestions extends ConsumerWidget {
  const _RegularSuggestions({required this.customerId, required this.draft});

  final String customerId;
  final CartDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final items = ref.watch(regularMaalProvider(customerId)).value ?? const <RegularMaalItem>[];
    final inCart = {for (final l in draft.lines) l.productId};
    final suggestions = items.where((i) => i.isOrderable && !inCart.contains(i.productId)).take(12).toList();
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.regularMaalTitle, style: text.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final item in suggestions)
                ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 18),
                  label: Text('${item.designNo} × ${item.lastQty}'),
                  tooltip: item.name,
                  onPressed: () => ref
                      .read(cartProvider.notifier)
                      .addQuoted(
                        QuotedProduct(
                          productId: item.productId,
                          designNo: item.designNo,
                          name: item.name,
                          rate: item.rate,
                          isOrderable: item.isOrderable,
                          thumbPath: item.thumbPath,
                        ),
                        qty: item.lastQty,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    super.key,
    required this.line,
    required this.onQty,
    required this.onEditQty,
    required this.onRemove,
  });

  final CartLine line;
  final ValueChanged<int> onQty;
  final VoidCallback onEditQty;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Opacity(
        opacity: line.isOrderable ? 1 : 0.55,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppRadius.control,
              child: SizedBox.square(
                dimension: 64,
                child: RemoteImage(path: line.thumbPath, decodeWidth: 64, semanticLabel: line.name),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(line.designNo, style: text.titleMedium!.copyWith(fontFeatures: AppType.figures)),
                      const Spacer(),
                      MoneyText(line.amount, style: text.titleMedium),
                    ],
                  ),
                  Text(
                    '${line.name} · ${line.rate.format()}',
                    style: text.bodySmall!.copyWith(color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (line.hasSpecialRate || !line.isOrderable)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxs),
                      child: StatusChip(
                        label: line.isOrderable ? l10n.specialRateBadge : l10n.productNotAvailable,
                        tone: line.isOrderable ? StatusTone.accent : StatusTone.error,
                      ),
                    ),
                  Row(
                    children: [
                      GestureDetector(
                        onLongPress: onEditQty,
                        child: QuantityStepper(
                          value: line.qty,
                          max: OrderLimits.maxQty,
                          decreaseLabel: l10n.qtyLess,
                          increaseLabel: l10n.qtyMore,
                          onChanged: onQty,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.quickAddQty,
                        icon: const Icon(Icons.dialpad_rounded),
                        onPressed: onEditQty,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: l10n.commonRemove,
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: onRemove,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentFields extends StatelessWidget {
  const _PaymentFields({required this.amount, required this.reference, required this.mode, required this.onMode});

  final TextEditingController amount;
  final TextEditingController reference;
  final PaymentMode mode;
  final ValueChanged<PaymentMode> onMode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          decoration: InputDecoration(labelText: l10n.fieldAmount, prefixText: '₹ '),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final m in PaymentMode.values)
              ChoiceChip(label: Text(paymentModeLabel(l10n, m)), selected: mode == m, onSelected: (_) => onMode(m)),
          ],
        ),
        if (mode != PaymentMode.cash) ...[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: reference,
            maxLength: 60, // server limit
            decoration: InputDecoration(labelText: l10n.fieldReference),
          ),
        ],
      ],
    );
  }
}
