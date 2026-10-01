import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../auth/auth.dart';
import '../domain/orders.dart';

/// Overridden at the composition root and in tests.
final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => throw UnimplementedError('ordersRepositoryProvider must be overridden'),
);

typedef OrderListState = PagedState<OrderSummary, OrderCursor>;

final orderListProvider = NotifierProvider.autoDispose.family<OrderList, OrderListState, OrderQuery>(OrderList.new);

class OrderList extends Notifier<OrderListState> {
  OrderList(this.query);

  final OrderQuery query;
  Paginator<OrderSummary, OrderCursor>? _paginator;

  @override
  OrderListState build() {
    ref
      ..watch(currentSessionProvider.select((s) => s?.tenantId))
      ..watch(businessRevisionProvider);
    final paginator = Paginator<OrderSummary, OrderCursor>(
      (cursor) => ref.read(ordersRepositoryProvider).page(query, after: cursor),
      (s) {
        if (ref.mounted) state = s;
      },
    );
    _paginator = paginator;
    unawaited(Future.microtask(paginator.refresh));
    return const OrderListState();
  }

  Future<void> refresh() => _paginator?.refresh() ?? Future.value();
  Future<void> loadMore() => _paginator?.loadMore() ?? Future.value();
  Future<void> retry() => _paginator?.retry() ?? Future.value();
}

final orderDetailProvider = FutureProvider.autoDispose.family<OrderDetail?, String>((ref, id) {
  ref
    ..watch(currentSessionProvider.select((s) => s?.tenantId))
    ..watch(businessRevisionProvider);
  return ref.watch(ordersRepositoryProvider).detail(id);
});

/// Status changes and cancellation.
final orderManagerProvider = Provider<OrderManager>(OrderManager.new);

class OrderManager {
  OrderManager(this._ref);

  final Ref _ref;

  Future<void> transition(String orderId, OrderStatus to) async {
    await _ref.read(ordersRepositoryProvider).transition(orderId, to);
    _ref.read(businessRevisionProvider.notifier).bump();
  }

  /// Reverses the order's effect on Baki (server side, in one transaction).
  Future<void> cancel(String orderId, {String? reason}) async {
    await _ref.read(ordersRepositoryProvider).cancel(orderId, reason: reason);
    _ref.read(businessRevisionProvider.notifier).bump();
  }
}
