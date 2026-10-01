import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../auth/auth.dart';
import '../domain/customers.dart';

/// Overridden at the composition root and in tests.
final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => throw UnimplementedError('customerRepositoryProvider must be overridden'),
);

typedef CustomerListState = PagedState<CustomerSummary, CustomerCursor>;

final customerListProvider = NotifierProvider.autoDispose.family<CustomerList, CustomerListState, CustomerQuery>(
  CustomerList.new,
);

class CustomerList extends Notifier<CustomerListState> {
  CustomerList(this.query);

  final CustomerQuery query;
  Paginator<CustomerSummary, CustomerCursor>? _paginator;

  @override
  CustomerListState build() {
    ref
      ..watch(currentSessionProvider.select((s) => s?.tenantId))
      ..watch(businessRevisionProvider); // Baki and activity change with orders/payments
    final paginator = Paginator<CustomerSummary, CustomerCursor>(
      (cursor) => ref.read(customerRepositoryProvider).page(query, after: cursor),
      (s) {
        if (ref.mounted) state = s;
      },
    );
    _paginator = paginator;
    unawaited(Future.microtask(paginator.refresh));
    return const CustomerListState();
  }

  Future<void> refresh() => _paginator?.refresh() ?? Future.value();
  Future<void> loadMore() => _paginator?.loadMore() ?? Future.value();
  Future<void> retry() => _paginator?.retry() ?? Future.value();
}

final customerDetailProvider = FutureProvider.autoDispose.family<CustomerDetail?, String>((ref, id) {
  ref
    ..watch(currentSessionProvider.select((s) => s?.tenantId))
    ..watch(businessRevisionProvider);
  return ref.watch(customerRepositoryProvider).detail(id);
});

final regularMaalProvider = FutureProvider.autoDispose.family<List<RegularMaalItem>, String>((ref, id) {
  ref
    ..watch(currentSessionProvider.select((s) => s?.tenantId))
    ..watch(businessRevisionProvider);
  return ref.watch(customerRepositoryProvider).regularMaal(id);
});

final customerRatesProvider = FutureProvider.autoDispose.family<List<CustomerRate>, String>((ref, id) {
  ref.watch(currentSessionProvider.select((s) => s?.tenantId));
  return ref.watch(customerRepositoryProvider).rates(id);
});

/// Outcome of creating a customer with an opening Baki.
enum OpeningBakiResult { notRequested, saved, failed }

/// Customer writes. Stateless; refreshes every affected read after a change.
final customerEditorProvider = Provider<CustomerEditorService>(CustomerEditorService.new);

class CustomerEditorService {
  CustomerEditorService(this._ref);

  final Ref _ref;

  CustomerRepository get _repo => _ref.read(customerRepositoryProvider);

  /// Creates the customer, then posts the opening Baki (needs hisaab.adjust).
  /// A failed opening never undoes the customer: the caller is told so the
  /// user can add it from Hisaab. [openingRequestId] makes a retry safe.
  Future<({String id, OpeningBakiResult opening})> create(
    CustomerDraft draft, {
    Money? openingBaki,
    required String openingRequestId,
  }) async {
    final id = await _repo.create(draft);
    _ref.invalidate(customerListProvider);
    if (openingBaki == null || openingBaki.paise == 0) return (id: id, opening: OpeningBakiResult.notRequested);
    try {
      await _repo.recordOpeningBalance(id, openingBaki, requestId: openingRequestId);
      return (id: id, opening: OpeningBakiResult.saved);
    } on AppFailure {
      return (id: id, opening: OpeningBakiResult.failed);
    }
  }

  Future<void> update(String id, CustomerDraft draft) async {
    await _repo.update(id, draft);
    _invalidate(id);
  }

  Future<void> setArchived(String id, {required bool archived}) async {
    await _repo.setArchived(id, archived: archived);
    _invalidate(id);
  }

  Future<ProductRef?> findDesign(String customerId, String designNo) => _repo.findDesign(customerId, designNo);

  Future<void> setRate(String customerId, String productId, Money rate) async {
    await _repo.setRate(customerId, productId, rate);
    _invalidateRates(customerId);
  }

  Future<void> removeRate(String customerId, String productId) async {
    await _repo.removeRate(customerId, productId);
    _invalidateRates(customerId);
  }

  void _invalidate(String id) {
    _ref
      ..invalidate(customerDetailProvider(id))
      ..invalidate(customerListProvider);
  }

  void _invalidateRates(String id) {
    _ref
      ..invalidate(customerRatesProvider(id))
      ..invalidate(customerDetailProvider(id))
      ..invalidate(regularMaalProvider(id));
  }
}
