import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../auth/auth.dart';
import '../domain/orders.dart';
import 'order_providers.dart';

/// Overridden at the composition root and in tests.
final cartStoreProvider = Provider<CartDraftStore>(
  (ref) => throw UnimplementedError('cartStoreProvider must be overridden'),
);

/// Why an order could not be placed, beyond a plain failure.
enum CartProblem { noCustomer, empty, unavailable }

class CartException implements Exception {
  const CartException(this.problem);

  final CartProblem problem;
}

/// The one cart for the signed-in identity. Kept on the device; prices are
/// what the server quoted for the chosen customer and are re-checked by the
/// server when the order is placed.
final cartProvider = NotifierProvider<CartController, CartDraft>(CartController.new);

class CartController extends Notifier<CartDraft> {
  String? _scope;

  OrdersRepository get _repo => ref.read(ordersRepositoryProvider);

  @override
  CartDraft build() {
    final identity = ref.watch(currentSessionProvider.select((s) => s == null ? null : '${s.tenantId}/${s.userId}'));
    _scope = identity;
    return (identity == null ? null : ref.read(cartStoreProvider).read(identity)) ?? CartDraft(requestId: newUuid());
  }

  /// Every change is a new intent → new request id; the draft is persisted.
  void _set(CartDraft Function(String requestId) next) {
    state = next(newUuid());
    final scope = _scope;
    if (scope != null) unawaited(ref.read(cartStoreProvider).write(scope, state));
  }

  /// Chooses the customer and re-prices every line at their rates.
  Future<void> selectCustomer(String customerId, String customerName) async {
    if (state.customerId == customerId) return;
    _set((id) => state.copyWith(requestId: id, customerId: customerId, customerName: customerName));
    await _reprice();
  }

  Future<void> _reprice() async {
    if (state.lines.isEmpty) return;
    final quotes = await _repo.quote(state.customerId, productIds: [for (final l in state.lines) l.productId]);
    final byId = {for (final q in quotes) q.productId: q};
    _set(
      (id) => state.copyWith(
        requestId: id,
        lines: [
          for (final l in state.lines)
            if (byId[l.productId] case final q?)
              l.copyWith(rate: q.rate, isOrderable: q.isOrderable, defaultRate: q.defaultRate)
            else
              l.copyWith(isOrderable: false),
        ],
      ),
    );
  }

  /// Adds [qty] pieces of a design, priced for the current customer.
  Future<void> addProduct(String productId, {int qty = 1}) async {
    final existing = state.lines.where((l) => l.productId == productId).firstOrNull;
    if (existing != null) return setQty(productId, existing.qty + qty);
    final quotes = await _repo.quote(state.customerId, productIds: [productId]);
    if (quotes.isEmpty) throw const AppFailure(FailureKind.notFound);
    addQuoted(quotes.single, qty: qty);
  }

  /// Adds by design number (quick order). Returns null when there is no such
  /// design; the quoted product otherwise (it may be unavailable).
  Future<QuotedProduct?> addDesignNo(String designNo, {int qty = 1}) async {
    final quotes = await _repo.quote(state.customerId, designNos: [designNo.trim()]);
    if (quotes.isEmpty) return null;
    final q = quotes.first;
    if (q.isOrderable) {
      final existing = state.lines.where((l) => l.productId == q.productId).firstOrNull;
      existing == null ? addQuoted(q, qty: qty) : setQty(q.productId, existing.qty + qty);
    }
    return q;
  }

  /// Adds an already-priced design (Regular Maal, quick order).
  void addQuoted(QuotedProduct q, {int qty = 1}) {
    final existing = state.lines.where((l) => l.productId == q.productId).firstOrNull;
    if (existing != null) return setQty(q.productId, existing.qty + qty);
    if (state.lines.length >= OrderLimits.maxLines) throw const AppFailure(FailureKind.invalidInput);
    _set(
      (id) => state.copyWith(
        requestId: id,
        lines: [...state.lines, CartLine.fromQuote(q, qty.clamp(1, OrderLimits.maxQty))],
      ),
    );
  }

  void setQty(String productId, int qty) {
    if (qty <= 0) return remove(productId);
    _set(
      (id) => state.copyWith(
        requestId: id,
        lines: [
          for (final l in state.lines) l.productId == productId ? l.copyWith(qty: qty.clamp(1, OrderLimits.maxQty)) : l,
        ],
      ),
    );
  }

  void remove(String productId) =>
      _set((id) => state.copyWith(requestId: id, lines: [...state.lines.where((l) => l.productId != productId)]));

  void setNote(String note) => _set((id) => state.copyWith(requestId: id, note: note));

  /// Starts a fresh cart (optionally for a customer / as a Fari Order).
  void reset({String? customerId, String? customerName, List<CartLine> lines = const [], String? reorderOf}) {
    _set(
      (id) => CartDraft(
        requestId: id,
        customerId: customerId,
        customerName: customerName,
        lines: lines,
        reorderOf: reorderOf,
      ),
    );
  }

  /// Places the order. Retrying after a lost response reuses the same request
  /// id, so the server returns the first result instead of a duplicate.
  /// On `rate_changed` / `product_unavailable` the cart is updated to what the
  /// server says and the failure is rethrown for the screen to explain.
  Future<PlacedOrder> place({PaymentInput? payment}) async {
    final draft = state;
    if (draft.customerId == null) throw const CartException(CartProblem.noCustomer);
    if (draft.isEmpty) throw const CartException(CartProblem.empty);
    if (draft.hasUnavailable) throw const CartException(CartProblem.unavailable);
    try {
      final placed = await _repo.place(
        customerId: draft.customerId!,
        lines: [
          for (final l in draft.lines) OrderRequestLine(productId: l.productId, qty: l.qty, expectedRate: l.rate),
        ],
        requestId: draft.requestId,
        note: draft.note,
        reorderOf: draft.reorderOf,
        payment: payment,
      );
      if (ref.mounted) {
        // Only clear the cart this request was built from.
        if (identical(state, draft)) reset();
        ref.read(businessRevisionProvider.notifier).bump();
      }
      return placed;
    } on AppFailure catch (f) {
      if (ref.mounted && identical(state, draft)) {
        if (f.kind == FailureKind.rateChanged) _applyRates(rateUpdatesFromDetails(f.details));
        if (f.kind == FailureKind.productUnavailable) _markUnavailable(unavailableFromDetails(f.details));
      }
      rethrow;
    }
  }

  void _applyRates(List<RateUpdate> updates) {
    if (updates.isEmpty) return;
    final byId = {for (final u in updates) u.productId: u.rate};
    _set(
      (id) => state.copyWith(
        requestId: id,
        lines: [for (final l in state.lines) byId[l.productId] == null ? l : l.copyWith(rate: byId[l.productId])],
      ),
    );
  }

  void _markUnavailable(Set<String> productIds) {
    if (productIds.isEmpty) return;
    _set(
      (id) => state.copyWith(
        requestId: id,
        lines: [for (final l in state.lines) productIds.contains(l.productId) ? l.copyWith(isOrderable: false) : l],
      ),
    );
  }
}
