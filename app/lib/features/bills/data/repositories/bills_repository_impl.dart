import '../../domain/bills.dart';
import '../remote/bills_api.dart';

class BillsRepositoryImpl implements BillsRepository {
  const BillsRepositoryImpl(this._remote);

  final BillsApi _remote;

  @override
  Future<IssuedBill> issue(String orderId) => _remote.issue(orderId);

  @override
  Future<BillDocument?> document(String billId) => _remote.document(billId);
}
