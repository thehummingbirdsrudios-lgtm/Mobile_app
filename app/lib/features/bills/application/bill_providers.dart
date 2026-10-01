import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../auth/auth.dart';
import '../domain/bills.dart';

/// Overridden at the composition root and in tests.
final billsRepositoryProvider = Provider<BillsRepository>(
  (ref) => throw UnimplementedError('billsRepositoryProvider must be overridden'),
);

final billDocumentProvider = FutureProvider.autoDispose.family<BillDocument?, String>((ref, billId) {
  ref.watch(currentSessionProvider.select((s) => s?.tenantId));
  return ref.watch(billsRepositoryProvider).document(billId);
});

final billIssuerProvider = Provider<BillIssuer>(BillIssuer.new);

class BillIssuer {
  BillIssuer(this._ref);

  final Ref _ref;

  /// One bill per order; issuing again returns the same bill.
  Future<IssuedBill> issue(String orderId) async {
    final bill = await _ref.read(billsRepositoryProvider).issue(orderId);
    _ref.read(businessRevisionProvider.notifier).bump();
    return bill;
  }
}
