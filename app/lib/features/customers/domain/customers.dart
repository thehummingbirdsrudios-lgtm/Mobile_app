import 'package:meta/meta.dart';

import '../../../core/money/money.dart';
import '../../../core/state/paged.dart';

/// A row in the customer list. [baki] is null when the member may not see
/// Hisaab (the server hides it; the app never computes it).
@immutable
class CustomerSummary {
  const CustomerSummary({
    required this.id,
    required this.name,
    this.shopName,
    this.city,
    this.phone,
    this.whatsappPhone,
    this.baki,
    this.lastActivityAt,
  });

  final String id;
  final String name;
  final String? shopName;
  final String? city;
  final String? phone;
  final String? whatsappPhone;
  final Money? baki;
  final DateTime? lastActivityAt;

  /// "Shop · City" (whatever is known).
  String? get place => [?shopName, ?city].where((s) => s.trim().isNotEmpty).join(' · ').emptyToNull;
}

enum CustomerSort { name, baki }

@immutable
class CustomerQuery {
  const CustomerQuery({this.search = '', this.sort = CustomerSort.name});

  final String search;
  final CustomerSort sort;

  @override
  bool operator ==(Object other) => other is CustomerQuery && other.search == search && other.sort == sort;

  @override
  int get hashCode => Object.hash(search, sort);
}

typedef CustomerCursor = ({String key, String id});

@immutable
class CustomerDetail {
  const CustomerDetail({
    required this.id,
    required this.name,
    required this.isArchived,
    required this.orderCount,
    required this.openOrders,
    required this.specialRates,
    this.shopName,
    this.city,
    this.phone,
    this.whatsappPhone,
    this.notes,
    this.baki,
    this.lastOrderAt,
  });

  final String id;
  final String name;
  final bool isArchived;
  final int orderCount;
  final int openOrders;
  final int specialRates;
  final String? shopName;
  final String? city;
  final String? phone;
  final String? whatsappPhone;
  final String? notes;
  final Money? baki;
  final DateTime? lastOrderAt;

  String? get place => [?shopName, ?city].where((s) => s.trim().isNotEmpty).join(' · ').emptyToNull;

  /// The number to message on WhatsApp (falls back to the mobile number).
  String? get whatsappNumber => whatsappPhone ?? phone;
}

/// What this customer usually takes — for one-tap re-ordering.
@immutable
class RegularMaalItem {
  const RegularMaalItem({
    required this.productId,
    required this.designNo,
    required this.name,
    required this.timesOrdered,
    required this.lastQty,
    required this.rate,
    required this.isOrderable,
    this.lastOrderedAt,
    this.thumbPath,
  });

  final String productId;
  final String designNo;
  final String name;
  final int timesOrdered;
  final int lastQty;
  final Money rate;
  final bool isOrderable;
  final DateTime? lastOrderedAt;
  final String? thumbPath;
}

/// A special (per-customer) selling rate.
@immutable
class CustomerRate {
  const CustomerRate({
    required this.productId,
    required this.designNo,
    required this.name,
    required this.defaultRate,
    required this.rate,
  });

  final String productId;
  final String designNo;
  final String name;
  final Money defaultRate;
  final Money rate;
}

/// A design found by its number (used to add a special rate).
@immutable
class ProductRef {
  const ProductRef({required this.productId, required this.designNo, required this.name, required this.defaultRate});

  final String productId;
  final String designNo;
  final String name;
  final Money defaultRate;
}

enum CustomerIssue { nameRequired, nameTooLong, phoneInvalid, whatsappInvalid, tooLong }

@immutable
class CustomerDraft {
  const CustomerDraft({
    required this.name,
    this.shopName = '',
    this.city = '',
    this.phone = '',
    this.whatsappPhone = '',
    this.notes = '',
  });

  final String name;
  final String shopName;
  final String city;
  final String phone;
  final String whatsappPhone;
  final String notes;

  /// Keeps digits and a leading +; Indian numbers are stored as 10 digits
  /// ("+91 98250 12345" → "9825012345"). Null when empty.
  static String? normalisePhone(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return trimmed; // fails validation
    if (digits.length == 12 && digits.startsWith('91')) return digits.substring(2);
    if (!trimmed.startsWith('+') && digits.length == 11 && digits.startsWith('0')) return digits.substring(1);
    return trimmed.startsWith('+') ? '+$digits' : digits;
  }

  static final _phonePattern = RegExp(r'^\+?[0-9]{10,15}$');

  static bool isValidPhone(String? normalised) => normalised == null || _phonePattern.hasMatch(normalised);

  /// Mirrors the database CHECK constraints.
  Set<CustomerIssue> validate() => {
    if (name.trim().isEmpty) CustomerIssue.nameRequired,
    if (name.trim().length > 120) CustomerIssue.nameTooLong,
    if (!isValidPhone(normalisePhone(phone))) CustomerIssue.phoneInvalid,
    if (!isValidPhone(normalisePhone(whatsappPhone))) CustomerIssue.whatsappInvalid,
    if (shopName.trim().length > 120 || city.trim().length > 60 || notes.trim().length > 1000) CustomerIssue.tooLong,
  };
}

/// Customers port. Implementations throw `AppFailure`.
abstract interface class CustomerRepository {
  Future<PageResult<CustomerSummary, CustomerCursor>> page(CustomerQuery query, {CustomerCursor? after, int limit});

  Future<CustomerDetail?> detail(String customerId);

  /// Creates a customer and returns its id.
  Future<String> create(CustomerDraft draft);

  Future<void> update(String customerId, CustomerDraft draft);

  Future<void> setArchived(String customerId, {required bool archived});

  /// Posts the opening Baki once (idempotent on [requestId]).
  Future<void> recordOpeningBalance(String customerId, Money amount, {required String requestId});

  Future<List<RegularMaalItem>> regularMaal(String customerId, {int limit});

  Future<List<CustomerRate>> rates(String customerId);

  /// Finds a design by number; null when there is none.
  Future<ProductRef?> findDesign(String customerId, String designNo);

  Future<void> setRate(String customerId, String productId, Money rate);

  Future<void> removeRate(String customerId, String productId);
}

extension on String {
  String? get emptyToNull => isEmpty ? null : this;
}
