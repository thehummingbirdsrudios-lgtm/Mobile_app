import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../auth/auth.dart';
import '../domain/hisaab.dart';

/// Overridden at the composition root and in tests.
final hisaabRepositoryProvider = Provider<HisaabRepository>(
  (ref) => throw UnimplementedError('hisaabRepositoryProvider must be overridden'),
);

typedef LedgerState = PagedState<LedgerEntry, LedgerCursor>;

/// A customer's Hisaab, newest first.
final ledgerProvider = NotifierProvider.autoDispose.family<Ledger, LedgerState, String>(Ledger.new);

class Ledger extends Notifier<LedgerState> {
  Ledger(this.customerId);

  final String customerId;
  Paginator<LedgerEntry, LedgerCursor>? _paginator;

  @override
  LedgerState build() {
    ref
      ..watch(currentSessionProvider.select((s) => s?.tenantId))
      ..watch(businessRevisionProvider);
    final paginator = Paginator<LedgerEntry, LedgerCursor>(
      (cursor) => ref.read(hisaabRepositoryProvider).ledger(customerId, before: cursor),
      (s) {
        if (ref.mounted) state = s;
      },
    );
    _paginator = paginator;
    unawaited(Future.microtask(paginator.refresh));
    return const LedgerState();
  }

  Future<void> refresh() => _paginator?.refresh() ?? Future.value();
  Future<void> loadMore() => _paginator?.loadMore() ?? Future.value();
  Future<void> retry() => _paginator?.retry() ?? Future.value();
}

final paymentReceiptProvider = FutureProvider.autoDispose.family<PaymentReceipt?, String>((ref, paymentId) {
  ref.watch(currentSessionProvider.select((s) => s?.tenantId));
  return ref.watch(hisaabRepositoryProvider).receipt(paymentId);
});

/// Money writes. Each form passes its own request id so a retry after a lost
/// response returns the first result instead of recording twice.
final hisaabWriterProvider = Provider<HisaabWriter>(HisaabWriter.new);

class HisaabWriter {
  HisaabWriter(this._ref);

  final Ref _ref;

  Future<RecordedPayment> recordPayment({
    required String customerId,
    required Money amount,
    required PaymentMode mode,
    required String requestId,
    String? reference,
    String? note,
  }) async {
    final result = await _ref
        .read(hisaabRepositoryProvider)
        .recordPayment(
          customerId: customerId,
          amount: amount,
          mode: mode,
          requestId: requestId,
          reference: reference,
          note: note,
        );
    _ref.read(businessRevisionProvider.notifier).bump();
    return result;
  }

  Future<void> recordAdjustment({
    required String customerId,
    required Money amount,
    required String requestId,
    required bool opening,
    String? note,
  }) async {
    await _ref
        .read(hisaabRepositoryProvider)
        .recordAdjustment(customerId: customerId, amount: amount, requestId: requestId, opening: opening, note: note);
    _ref.read(businessRevisionProvider.notifier).bump();
  }
}
