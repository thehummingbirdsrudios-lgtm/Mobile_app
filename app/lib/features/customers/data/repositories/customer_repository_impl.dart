import '../../../../core/money/money.dart';
import '../../../../core/state/paged.dart';
import '../../domain/customers.dart';
import '../remote/customers_api.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  const CustomerRepositoryImpl(this._remote);

  final CustomersApi _remote;

  @override
  Future<PageResult<CustomerSummary, CustomerCursor>> page(
    CustomerQuery query, {
    CustomerCursor? after,
    int limit = 30,
  }) => _remote.page(query, after: after, limit: limit);

  @override
  Future<CustomerDetail?> detail(String customerId) => _remote.detail(customerId);

  @override
  Future<String> create(CustomerDraft draft) => _remote.insert(customerColumns(draft));

  @override
  Future<void> update(String customerId, CustomerDraft draft) => _remote.update(customerId, customerColumns(draft));

  @override
  Future<void> setArchived(String customerId, {required bool archived}) =>
      _remote.update(customerId, {'archived_at': archived ? DateTime.now().toUtc().toIso8601String() : null});

  @override
  Future<void> recordOpeningBalance(String customerId, Money amount, {required String requestId}) =>
      _remote.recordAdjustment(customerId, 'opening', amount.paise, requestId);

  @override
  Future<List<RegularMaalItem>> regularMaal(String customerId, {int limit = 20}) =>
      _remote.regularMaal(customerId, limit: limit);

  @override
  Future<List<CustomerRate>> rates(String customerId) => _remote.rates(customerId);

  @override
  Future<ProductRef?> findDesign(String customerId, String designNo) => _remote.findDesign(customerId, designNo);

  @override
  Future<void> setRate(String customerId, String productId, Money rate) =>
      _remote.upsertRate(customerId, productId, rate.paise);

  @override
  Future<void> removeRate(String customerId, String productId) => _remote.deleteRate(customerId, productId);
}
