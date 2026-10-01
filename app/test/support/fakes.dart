import 'dart:async';
import 'dart:typed_data';

import 'package:vepari/core/core.dart';
import 'package:vepari/features/auth/auth.dart';
import 'package:vepari/features/bills/bills.dart';
import 'package:vepari/features/catalogue/catalogue.dart';
import 'package:vepari/features/catalogue/domain/catalogue.dart'
    show CatalogueCursor, PhotoUpload, ProductDraft, ProductPrivate;
import 'package:vepari/features/customers/customers.dart';
import 'package:vepari/features/customers/domain/customers.dart' show CustomerCursor, CustomerDraft;
import 'package:vepari/features/dashboard/dashboard.dart';
import 'package:vepari/features/hisaab/domain/hisaab.dart' show LedgerCursor;
import 'package:vepari/features/hisaab/hisaab.dart';
import 'package:vepari/features/orders/domain/orders.dart'
    show OrderCursor, OrderLine, OrderCustomer, OrderRequestLine, PaymentInput, PlacedOrder, ReorderLine;
import 'package:vepari/features/orders/orders.dart';
import 'package:vepari/features/remarks/remarks.dart';
import 'package:vepari/features/search/search.dart';
import 'package:vepari/features/settings/settings.dart';
import 'package:vepari/features/sharing/sharing.dart';

const ownerSession = UserSession(
  userId: 'u-owner',
  tenantId: 't-a',
  username: 'rajesh',
  displayName: 'Rajeshbhai',
  businessName: 'Shree Jewels',
  role: MemberRole.owner,
  permissions: {},
);

const staffSession = UserSession(
  userId: 'u-staff',
  tenantId: 't-a',
  username: 'mahesh',
  displayName: 'Maheshbhai',
  businessName: 'Shree Jewels',
  role: MemberRole.staff,
  permissions: {Permission.ordersCreate},
);

/// Scriptable [AuthRepository] that records calls.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.restored, this.signInResult, this.signInError, this.restoreError});

  UserSession? restored;
  UserSession? signInResult;
  AppFailure? signInError;
  AppFailure? restoreError;
  Completer<void>? signInGate;
  int signInCalls = 0;
  int signOutCalls = 0;
  String? lastUsername;
  final _ended = StreamController<void>.broadcast();

  void endSession() => _ended.add(null);

  @override
  Stream<void> get sessionEnded => _ended.stream;

  @override
  Future<UserSession?> restore() async {
    if (restoreError != null) throw restoreError!;
    return restored;
  }

  @override
  Future<UserSession> signIn({required String username, required String password}) async {
    signInCalls++;
    lastUsername = username;
    if (signInGate != null) await signInGate!.future;
    if (signInError != null) throw signInError!;
    return signInResult!;
  }

  @override
  Future<void> signOut() async => signOutCalls++;

  Future<void> dispose() => _ended.close();
}

class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({this.summary, this.error});

  DashboardSummary? summary;
  AppFailure? error;
  int calls = 0;

  /// When true, fetches wait until [release] (to observe loading states).
  bool gate = false;
  final _gate = Completer<void>();

  void release() => _gate.complete();

  @override
  Future<DashboardSummary> fetchSummary() async {
    calls++;
    if (gate) await _gate.future;
    if (error != null) throw error!;
    return summary!;
  }
}

class MemoryPreferenceStore implements PreferenceStore {
  final values = <String, String>{};

  @override
  String? getString(String key) => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}

const sampleSummary = DashboardSummary(
  salesToday: Money.paise(3850000),
  paymentsToday: Money.paise(2200000),
  totalBaki: Money.paise(48200000),
  ordersToday: 7,
  pendingOrders: 3,
  newMaalLast7Days: 12,
);

// ---------------------------------------------------------------------------
// Catalogue
// ---------------------------------------------------------------------------
class FakeCatalogueRepository implements CatalogueRepository {
  FakeCatalogueRepository({List<ProductDetail>? products}) : products = products ?? sampleProducts();

  final List<ProductDetail> products;
  final categoriesList = <Category>[const Category(id: 'cat-1', name: 'Kundan')];
  final addedPhotos = <(String, PhotoUpload)>[];
  final updates = <(String, ProductDraft, bool)>[];
  AppFailure? createError;
  AppFailure? pageError;
  int pageCalls = 0;

  @override
  Future<PageResult<ProductSummary, CatalogueCursor>> page(
    CatalogueFilter filter, {
    CatalogueCursor? after,
    int limit = 30,
  }) async {
    pageCalls++;
    if (pageError != null) throw pageError!;
    final visible = products
        .where((p) => !p.isArchived)
        .where((p) => filter.categoryId == null || p.categoryId == filter.categoryId)
        .where((p) => filter.newSince == null || !p.publishedAt.isBefore(filter.newSince!))
        .toList();
    final start = after == null ? 0 : visible.indexWhere((p) => p.id == after.id) + 1;
    final slice = visible.skip(start).take(limit).toList();
    final items = [
      for (final p in slice)
        ProductSummary(
          id: p.id,
          designNo: p.designNo,
          name: p.name,
          rate: p.rate,
          isAvailable: p.isAvailable,
          publishedAt: p.publishedAt,
          weightMg: p.weightMg,
          thumbPath: p.photos.isEmpty ? null : p.photos.first.thumbPath,
        ),
    ];
    final more = start + limit < visible.length;
    return PageResult(items, next: more ? (publishedAt: slice.last.publishedAt, id: slice.last.id) : null);
  }

  @override
  Future<ProductDetail?> detail(String productId) async => products.where((p) => p.id == productId).firstOrNull;

  @override
  Future<List<Category>> categories() async => categoriesList;

  @override
  Future<Category> createCategory(String name) async {
    final c = Category(id: 'cat-${categoriesList.length + 1}', name: name);
    categoriesList.add(c);
    return c;
  }

  @override
  Future<String> create(ProductDraft draft, {required bool includePrivate}) async {
    if (createError != null) throw createError!;
    final id = '00000000-0000-4000-8000-${(products.length + 1).toString().padLeft(12, '0')}';
    products.add(
      ProductDetail(
        id: id,
        designNo: draft.designNo,
        name: draft.name,
        rate: draft.rate!,
        isAvailable: draft.isAvailable,
        isArchived: false,
        publishedAt: DateTime.now(),
        photos: const [],
        weightMg: draft.weightMg,
      ),
    );
    return id;
  }

  @override
  Future<void> update(
    String productId,
    ProductDraft draft, {
    required bool includeRate,
    required bool includePrivate,
  }) async {
    updates.add((productId, draft, includeRate));
  }

  @override
  Future<void> setArchived(String productId, {required bool archived}) async {
    final i = products.indexWhere((p) => p.id == productId);
    final p = products[i];
    products[i] = ProductDetail(
      id: p.id,
      designNo: p.designNo,
      name: p.name,
      rate: p.rate,
      isAvailable: p.isAvailable,
      isArchived: archived,
      publishedAt: p.publishedAt,
      photos: p.photos,
    );
  }

  @override
  Future<void> addPhoto(String productId, PhotoUpload upload) async => addedPhotos.add((productId, upload));

  @override
  Future<void> removePhoto(String photoId) async {}
}

const productKundanId = '00000000-0000-4000-8000-000000001024';
const productJhumkaId = '00000000-0000-4000-8000-000000001025';

List<ProductDetail> sampleProducts() => [
  ProductDetail(
    id: productKundanId,
    designNo: '1024',
    name: 'Kundan Set',
    rate: const Money.paise(62000),
    isAvailable: true,
    isArchived: false,
    publishedAt: DateTime.now().subtract(const Duration(days: 1)),
    weightMg: 42000,
    categoryId: 'cat-1',
    categoryName: 'Kundan',
    photos: const [ProductPhoto(id: 'm1', thumbPath: 't/p/1024/thumb.jpg', cataloguePath: 't/p/1024/catalogue.jpg')],
    private: const ProductPrivate(cost: Money.paise(42000), supplierName: 'Secret Supplier', internalNote: 'Note'),
  ),
  ProductDetail(
    id: productJhumkaId,
    designNo: '1025',
    name: 'Jhumka',
    rate: const Money.paise(32000),
    isAvailable: false,
    isArchived: false,
    publishedAt: DateTime.now().subtract(const Duration(days: 30)),
    photos: const [],
  ),
];

/// Storage that never touches the network.
class FakeStorage implements StorageClient {
  final uploads = <String>[];

  @override
  Future<String> signedUrl(String bucket, String path, {Duration expiresIn = const Duration(hours: 1)}) async =>
      'https://storage.invalid/$bucket/$path';

  @override
  Future<void> upload(String bucket, String path, Uint8List bytes, {required String contentType}) async =>
      uploads.add('$bucket/$path');

  @override
  Future<Uint8List> download(String bucket, String path) async => Uint8List(0);
}

class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker([this.next]);

  Uint8List? next;

  @override
  Future<Uint8List?> pick(PhotoOrigin origin) async => next;
}

/// Records navigation instead of performing it.
class RecordingNavigator implements AppNavigator {
  final calls = <String>[];

  @override
  void noSuchMethod(Invocation invocation) => calls.add(
    '${invocation.memberName.toString().replaceAll('Symbol("', '').replaceAll('")', '')}'
    '${invocation.positionalArguments.isEmpty ? '' : ':${invocation.positionalArguments.join(',')}'}',
  );
}

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------
class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository({List<SearchHit>? hits}) : hits = hits ?? sampleHits;

  final List<SearchHit> hits;
  final recentByScope = <String, List<String>>{};
  final queries = <String>[];

  /// Queries that wait until their completer is completed.
  final gates = <String, Completer<void>>{};
  AppFailure? error;

  @override
  Future<SearchResults> search(String query, {int limitPerGroup = 8}) async {
    queries.add(query);
    final gate = gates[query];
    if (gate != null) await gate.future;
    if (error != null) throw error!;
    final q = query.toLowerCase();
    return SearchResults.fromHits(
      query,
      hits.where((h) => h.title.toLowerCase().contains(q) || (h.subtitle ?? '').toLowerCase().contains(q)),
    );
  }

  @override
  List<String> recent(String scope) => recentByScope[scope] ?? const [];

  @override
  Future<void> remember(String scope, String query) async =>
      recentByScope[scope] = [query, ...recent(scope).where((q) => q != query)];

  @override
  Future<void> clearRecent(String scope) async => recentByScope.remove(scope);
}

const customerPatelId = '00000000-0000-4000-8000-00000000c001';
const orderFirstId = '00000000-0000-4000-8000-00000000a001';

const sampleHits = [
  SearchHit(kind: SearchKind.product, id: productKundanId, title: '1024', subtitle: 'Kundan Set'),
  SearchHit(kind: SearchKind.customer, id: customerPatelId, title: 'Patel Kundan Stores', subtitle: 'Rajkot'),
  SearchHit(kind: SearchKind.order, id: orderFirstId, title: '1045', subtitle: 'Patel Kundan Stores'),
];

// ---------------------------------------------------------------------------
// Customers
// ---------------------------------------------------------------------------
const customerShahId = '00000000-0000-4000-8000-00000000c002';

class FakeCustomerRepository implements CustomerRepository {
  FakeCustomerRepository({List<CustomerDetail>? customers}) : customers = customers ?? sampleCustomers();

  final List<CustomerDetail> customers;
  final created = <CustomerDraft>[];
  final updates = <(String, CustomerDraft)>[];
  final openings = <(String, Money, String)>[];
  final rateList = <String, List<CustomerRate>>{};
  final regular = <String, List<RegularMaalItem>>{};
  final queries = <CustomerQuery>[];
  AppFailure? pageError;
  AppFailure? openingError;

  /// Whether Baki is visible to the caller (mirrors server RLS).
  bool hideBaki = false;

  @override
  Future<PageResult<CustomerSummary, CustomerCursor>> page(
    CustomerQuery query, {
    CustomerCursor? after,
    int limit = 30,
  }) async {
    queries.add(query);
    if (pageError != null) throw pageError!;
    final q = query.search.toLowerCase();
    var rows = customers
        .where((c) => !c.isArchived)
        .where((c) => q.isEmpty || c.name.toLowerCase().contains(q) || (c.phone ?? '').contains(q))
        .toList();
    if (query.sort == CustomerSort.baki) {
      rows = rows.where((c) => (c.baki?.paise ?? 0) != 0).toList()
        ..sort((a, b) => b.baki!.paise.compareTo(a.baki!.paise));
    } else {
      rows.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return PageResult([
      for (final c in rows)
        CustomerSummary(
          id: c.id,
          name: c.name,
          shopName: c.shopName,
          city: c.city,
          phone: c.phone,
          baki: hideBaki ? null : c.baki,
        ),
    ]);
  }

  @override
  Future<CustomerDetail?> detail(String customerId) async {
    final c = customers.where((c) => c.id == customerId).firstOrNull;
    if (c == null || !hideBaki) return c;
    return CustomerDetail(
      id: c.id,
      name: c.name,
      isArchived: c.isArchived,
      orderCount: c.orderCount,
      openOrders: c.openOrders,
      specialRates: c.specialRates,
      shopName: c.shopName,
      city: c.city,
      phone: c.phone,
      whatsappPhone: c.whatsappPhone,
      notes: c.notes,
      lastOrderAt: c.lastOrderAt,
    );
  }

  @override
  Future<String> create(CustomerDraft draft) async {
    created.add(draft);
    final id = '00000000-0000-4000-8000-${(0xc100 + created.length).toString().padLeft(12, '0')}';
    customers.add(
      CustomerDetail(
        id: id,
        name: draft.name.trim(),
        isArchived: false,
        orderCount: 0,
        openOrders: 0,
        specialRates: 0,
        phone: CustomerDraft.normalisePhone(draft.phone),
        baki: Money.zero,
      ),
    );
    return id;
  }

  @override
  Future<void> update(String customerId, CustomerDraft draft) async => updates.add((customerId, draft));

  @override
  Future<void> setArchived(String customerId, {required bool archived}) async {}

  @override
  Future<void> recordOpeningBalance(String customerId, Money amount, {required String requestId}) async {
    if (openingError != null) throw openingError!;
    openings.add((customerId, amount, requestId));
  }

  @override
  Future<List<RegularMaalItem>> regularMaal(String customerId, {int limit = 20}) async =>
      regular[customerId] ?? const [];

  @override
  Future<List<CustomerRate>> rates(String customerId) async => rateList[customerId] ?? const [];

  @override
  Future<ProductRef?> findDesign(String customerId, String designNo) async => designNo.toUpperCase() == '1024'
      ? const ProductRef(
          productId: productKundanId,
          designNo: '1024',
          name: 'Kundan Set',
          defaultRate: Money.paise(62000),
        )
      : null;

  @override
  Future<void> setRate(String customerId, String productId, Money rate) async {
    final list = [...?rateList[customerId]]..removeWhere((r) => r.productId == productId);
    list.add(
      CustomerRate(
        productId: productId,
        designNo: '1024',
        name: 'Kundan Set',
        defaultRate: const Money.paise(62000),
        rate: rate,
      ),
    );
    rateList[customerId] = list;
  }

  @override
  Future<void> removeRate(String customerId, String productId) async =>
      rateList[customerId]?.removeWhere((r) => r.productId == productId);
}

List<CustomerDetail> sampleCustomers() => [
  CustomerDetail(
    id: customerPatelId,
    name: 'Patel Kundan Stores',
    isArchived: false,
    orderCount: 12,
    openOrders: 2,
    specialRates: 1,
    city: 'Rajkot',
    phone: '9825012345',
    baki: const Money.paise(4820000),
    lastOrderAt: DateTime.utc(2026, 9, 28),
  ),
  const CustomerDetail(
    id: customerShahId,
    name: 'Shah Imitation',
    isArchived: false,
    orderCount: 0,
    openOrders: 0,
    specialRates: 0,
    shopName: 'Shah Fancy',
    city: 'Surat',
    baki: Money.paise(125000),
  ),
];

/// Records launches instead of opening apps.
class FakeContactLauncher implements ContactLauncher {
  final launched = <String>[];
  bool available = true;

  @override
  Future<bool> call(String phone) async {
    launched.add('tel:$phone');
    return available;
  }

  @override
  Future<bool> whatsapp(String phone, {String? text}) async {
    launched.add('wa:$phone');
    return available;
  }
}

// ---------------------------------------------------------------------------
// Orders
// ---------------------------------------------------------------------------
class PlaceCall {
  PlaceCall(this.customerId, this.lines, this.requestId, this.note, this.reorderOf, this.payment);

  final String customerId;
  final List<OrderRequestLine> lines;
  final String requestId;
  final String? note;
  final String? reorderOf;
  final PaymentInput? payment;
}

class FakeOrdersRepository implements OrdersRepository {
  FakeOrdersRepository({List<OrderDetail>? orders}) : orders = orders ?? sampleOrders();

  final List<OrderDetail> orders;
  final placeCalls = <PlaceCall>[];
  final transitions = <(String, OrderStatus)>[];
  final cancels = <(String, String?)>[];

  /// Thrown (once each, in order) by the next place() calls.
  final placeErrors = <AppFailure>[];

  /// Special rates: customerId → productId → paise.
  final special = <String, Map<String, int>>{};

  /// Designs that are no longer orderable.
  final unavailable = <String>{};
  final _requests = <String, PlacedOrder>{};
  int _nextNo = 1046;

  static final _catalogue = {for (final p in sampleProducts()) p.id: p};

  @override
  Future<PageResult<OrderSummary, OrderCursor>> page(OrderQuery query, {OrderCursor? after, int limit = 30}) async {
    final rows = orders
        .where((o) => query.customerId == null || o.customer.id == query.customerId)
        .where((o) => !query.pendingOnly || o.status.isOpen)
        .map(
          (o) => OrderSummary(
            id: o.id,
            orderNo: o.orderNo,
            customerId: o.customer.id,
            customerName: o.customer.name,
            status: o.status,
            totalQty: o.totalQty,
            total: o.total,
            createdAt: o.createdAt,
          ),
        )
        .toList();
    return PageResult(rows);
  }

  @override
  Future<OrderDetail?> detail(String orderId) async => orders.where((o) => o.id == orderId).firstOrNull;

  QuotedProduct _quote(String? customerId, ProductDetail p) => QuotedProduct(
    productId: p.id,
    designNo: p.designNo,
    name: p.name,
    rate: Money.paise(special[customerId]?[p.id] ?? p.rate.paise),
    defaultRate: p.rate,
    isOrderable: p.isAvailable && !unavailable.contains(p.id),
    weightMg: p.weightMg,
    thumbPath: p.photos.isEmpty ? null : p.photos.first.thumbPath,
  );

  @override
  Future<List<QuotedProduct>> quote(
    String? customerId, {
    List<String> productIds = const [],
    List<String> designNos = const [],
  }) async => [
    for (final id in productIds)
      if (_catalogue[id] case final p?) _quote(customerId, p),
    for (final no in designNos)
      for (final p in _catalogue.values)
        if (p.designNo.toUpperCase() == no.trim().toUpperCase()) _quote(customerId, p),
  ];

  @override
  Future<PlacedOrder> place({
    required String customerId,
    required List<OrderRequestLine> lines,
    required String requestId,
    String? note,
    String? reorderOf,
    PaymentInput? payment,
  }) async {
    placeCalls.add(PlaceCall(customerId, lines, requestId, note, reorderOf, payment));
    if (placeErrors.isNotEmpty) throw placeErrors.removeAt(0);
    final replay = _requests[requestId];
    if (replay != null) {
      return PlacedOrder(
        orderId: replay.orderId,
        orderNo: replay.orderNo,
        customerId: replay.customerId,
        totalQty: replay.totalQty,
        total: replay.total,
        replayed: true,
      );
    }
    final id = '00000000-0000-4000-8000-${(0xa000 + _nextNo).toString().padLeft(12, '0')}';
    final items = [
      for (final l in lines)
        OrderLine(
          productId: l.productId,
          designNo: _catalogue[l.productId]!.designNo,
          name: _catalogue[l.productId]!.name,
          rate: l.expectedRate,
          qty: l.qty,
          amount: l.expectedRate.times(l.qty),
        ),
    ];
    final total = items.fold(Money.zero, (sum, i) => sum + i.amount);
    final qty = items.fold(0, (sum, i) => sum + i.qty);
    final customer = sampleCustomers().firstWhere((c) => c.id == customerId);
    orders.insert(
      0,
      OrderDetail(
        id: id,
        orderNo: _nextNo,
        status: OrderStatus.confirmed,
        totalQty: qty,
        total: total,
        createdAt: DateTime.now().toUtc(),
        customer: OrderCustomer(id: customer.id, name: customer.name, city: customer.city),
        items: items,
        note: note,
        reorderOf: reorderOf,
      ),
    );
    final placed = PlacedOrder(
      orderId: id,
      orderNo: _nextNo++,
      customerId: customerId,
      totalQty: qty,
      total: total,
      replayed: false,
    );
    _requests[requestId] = placed;
    return placed;
  }

  @override
  Future<void> transition(String orderId, OrderStatus to) async {
    transitions.add((orderId, to));
    _replaceStatus(orderId, to);
  }

  @override
  Future<void> cancel(String orderId, {String? reason}) async {
    cancels.add((orderId, reason));
    _replaceStatus(orderId, OrderStatus.cancelled, reason: reason);
  }

  void _replaceStatus(String id, OrderStatus status, {String? reason}) {
    final i = orders.indexWhere((o) => o.id == id);
    final o = orders[i];
    orders[i] = OrderDetail(
      id: o.id,
      orderNo: o.orderNo,
      status: status,
      totalQty: o.totalQty,
      total: o.total,
      createdAt: o.createdAt,
      customer: o.customer,
      items: o.items,
      cancelReason: reason,
    );
  }

  @override
  Future<List<ReorderLine>> reorderPreview(String orderId) async {
    final o = orders.firstWhere((o) => o.id == orderId);
    return [
      for (final l in o.items)
        ReorderLine(
          productId: l.productId,
          designNo: l.designNo,
          name: l.name,
          qty: l.qty,
          oldRate: l.rate,
          rate: Money.paise(special[o.customer.id]?[l.productId] ?? _catalogue[l.productId]!.rate.paise),
          isOrderable: !unavailable.contains(l.productId) && _catalogue[l.productId]!.isAvailable,
        ),
    ];
  }
}

List<OrderDetail> sampleOrders() => [
  OrderDetail(
    id: orderFirstId,
    orderNo: 1045,
    status: OrderStatus.confirmed,
    totalQty: 12,
    total: const Money.paise(744000),
    createdAt: DateTime.utc(2026, 9, 30, 11),
    createdByName: 'Maheshbhai',
    customer: const OrderCustomer(id: customerPatelId, name: 'Patel Kundan Stores', city: 'Rajkot'),
    items: const [
      OrderLine(
        productId: productKundanId,
        designNo: '1024',
        name: 'Kundan Set',
        rate: Money.paise(62000),
        qty: 12,
        amount: Money.paise(744000),
      ),
    ],
  ),
];

class MemoryCartStore implements CartDraftStore {
  final drafts = <String, CartDraft?>{};

  @override
  CartDraft? read(String scope) => drafts[scope];

  @override
  Future<void> write(String scope, CartDraft? draft) async => drafts[scope] = draft;
}

// ---------------------------------------------------------------------------
// Hisaab
// ---------------------------------------------------------------------------
const paymentFirstId = '00000000-0000-4000-8000-00000000b001';

class PaymentCall {
  PaymentCall(this.customerId, this.amount, this.mode, this.requestId, this.reference, this.note);

  final String customerId;
  final Money amount;
  final PaymentMode mode;
  final String requestId;
  final String? reference;
  final String? note;
}

class FakeHisaabRepository implements HisaabRepository {
  FakeHisaabRepository({Map<String, List<LedgerEntry>>? ledgers})
    : ledgers = ledgers ?? {customerPatelId: sampleLedger()};

  final Map<String, List<LedgerEntry>> ledgers;
  final payments = <PaymentCall>[];
  final adjustments = <(String, Money, bool, String?, String)>[];
  final receipts = <String, PaymentReceipt>{paymentFirstId: sampleReceipt};
  final paymentErrors = <AppFailure>[];
  AppFailure? adjustmentError;
  int _nextNo = 8;

  @override
  Future<PageResult<LedgerEntry, LedgerCursor>> ledger(
    String customerId, {
    LedgerCursor? before,
    int limit = 50,
  }) async => PageResult(ledgers[customerId] ?? const []);

  @override
  Future<RecordedPayment> recordPayment({
    required String customerId,
    required Money amount,
    required PaymentMode mode,
    required String requestId,
    String? reference,
    String? note,
  }) async {
    payments.add(PaymentCall(customerId, amount, mode, requestId, reference, note));
    if (paymentErrors.isNotEmpty) throw paymentErrors.removeAt(0);
    final id = '00000000-0000-4000-8000-${(0xb000 + _nextNo).toString().padLeft(12, '0')}';
    final before = sampleCustomers().firstWhere((c) => c.id == customerId).baki!;
    receipts[id] = PaymentReceipt(
      paymentNo: _nextNo,
      amount: amount,
      mode: mode,
      reference: reference,
      receivedAt: DateTime.utc(2026, 10, 1, 10),
      balanceBefore: before,
      balanceAfter: before - amount,
      customerName: 'Patel Kundan Stores',
      customerPhone: '9825012345',
      businessName: 'Shree Jewels',
    );
    return RecordedPayment(
      paymentId: id,
      paymentNo: _nextNo++,
      amount: amount,
      balanceAfter: before - amount,
      replayed: false,
    );
  }

  @override
  Future<void> recordAdjustment({
    required String customerId,
    required Money amount,
    required String requestId,
    required bool opening,
    String? note,
  }) async {
    if (adjustmentError != null) throw adjustmentError!;
    adjustments.add((customerId, amount, opening, note, requestId));
  }

  @override
  Future<PaymentReceipt?> receipt(String paymentId) async => receipts[paymentId];
}

List<LedgerEntry> sampleLedger() => [
  LedgerEntry(
    id: 'l3',
    kind: LedgerKind.payment,
    amount: const Money.paise(-500000),
    balanceAfter: const Money.paise(4820000),
    createdAt: DateTime.utc(2026, 9, 30, 12),
    paymentId: paymentFirstId,
    paymentMode: PaymentMode.upi,
  ),
  LedgerEntry(
    id: 'l2',
    kind: LedgerKind.order,
    amount: const Money.paise(744000),
    balanceAfter: const Money.paise(5320000),
    createdAt: DateTime.utc(2026, 9, 30, 11),
    orderId: orderFirstId,
    orderNo: 1045,
  ),
  LedgerEntry(
    id: 'l1',
    kind: LedgerKind.opening,
    amount: const Money.paise(4576000),
    balanceAfter: const Money.paise(4576000),
    createdAt: DateTime.utc(2026, 9, 1),
  ),
];

final sampleReceipt = PaymentReceipt(
  paymentNo: 7,
  amount: const Money.paise(500000),
  mode: PaymentMode.upi,
  reference: 'UPI-881',
  receivedAt: DateTime.utc(2026, 9, 30, 12),
  balanceBefore: const Money.paise(5320000),
  balanceAfter: const Money.paise(4820000),
  customerName: 'Patel Kundan Stores',
  customerPhone: '9825012345',
  businessName: 'Shree Jewels',
  businessAddress: 'Soni Bazar, Rajkot',
);

// ---------------------------------------------------------------------------
// Bills and sharing
// ---------------------------------------------------------------------------
const billFirstId = '00000000-0000-4000-8000-00000000d001';

class FakeBillsRepository implements BillsRepository {
  final issued = <String>[];
  final documents = <String, BillDocument>{billFirstId: sampleBill};
  AppFailure? issueError;

  @override
  Future<IssuedBill> issue(String orderId) async {
    if (issueError != null) throw issueError!;
    issued.add(orderId);
    return const IssuedBill(billId: billFirstId, billNo: 12, replayed: false);
  }

  @override
  Future<BillDocument?> document(String billId) async => documents[billId];
}

final sampleBill = BillDocument(
  billNo: 12,
  issuedAt: DateTime.utc(2026, 10, 1, 10),
  orderNo: 1045,
  customerName: 'Patel Kundan Stores',
  customerPhone: '9825012345',
  business: const BillBusiness(name: 'Shree Jewels', address: 'Soni Bazar, Rajkot', footer: 'Thank you'),
  totalQty: 12,
  total: const Money.paise(744000),
  totalWeightMg: 504000,
  paid: const Money.paise(100000),
  balanceAfter: const Money.paise(5320000),
  items: const [
    BillItem(
      designNo: '1024',
      name: 'Kundan Set',
      qty: 12,
      rate: Money.paise(62000),
      amount: Money.paise(744000),
      weightMg: 42000,
      imagePath: 'p/1024.jpg', // served by FakeImageHost
    ),
  ],
);

class FakeFileSharer implements FileSharer {
  final shared = <(List<ShareFile>, String?)>[];
  bool available = true;

  @override
  Future<bool> share({List<ShareFile> files = const [], String? text}) async {
    shared.add((files, text));
    return available;
  }
}

class FakeSharingRepository implements SharingRepository {
  final requested = <(String, String?)>[];
  bool watermarkEnabled = true;

  @override
  Future<ShareableProduct> product(String productId, {String? customerId}) async {
    requested.add((productId, customerId));
    final p = sampleProducts().firstWhere(
      (p) => p.id == productId,
      orElse: () => throw const AppFailure(FailureKind.notFound),
    );
    return ShareableProduct(
      designNo: p.designNo,
      name: p.name,
      rate: p.rate,
      weightMg: p.weightMg,
      sharePath: p.photos.isEmpty ? null : 't-a/products/${p.id}/m/share.jpg',
      businessName: 'Shree Jewels',
      whatsappPhone: '9825000000',
      watermark: watermarkEnabled,
    );
  }

  @override
  Future<List<int>> photo(String sharePath) async => [0xFF, 0xD8, 0xFF, 0xD9];
}

// ---------------------------------------------------------------------------
// Vaat (remarks), voice
// ---------------------------------------------------------------------------
class FakeRemarksRepository implements RemarksRepository {
  final byTarget = <RemarkTarget, List<Remark>>{};
  final archived = <String>[];
  final uploads = <(String kind, String tenantId, int bytes, Duration? duration)>[];
  AppFailure? addError;
  int _n = 0;

  void _add(RemarkTarget target, Remark r) => byTarget[target] = [r, ...?byTarget[target]];

  Remark _make(RemarkKind kind, {String? text, String? path, Duration? duration}) => Remark(
    id: 'r${++_n}',
    kind: kind,
    createdAt: DateTime.utc(2026, 10, 1, 10, _n),
    text: text,
    mediaPath: path,
    duration: duration,
    authorId: 'u-owner',
    authorName: 'Rajeshbhai',
  );

  @override
  Future<List<Remark>> list(RemarkTarget target, {int limit = 50}) async => byTarget[target] ?? const [];

  @override
  Future<void> addText(RemarkTarget target, String text) async {
    if (addError != null) throw addError!;
    _add(target, _make(RemarkKind.text, text: text));
  }

  @override
  Future<void> addVoice(
    RemarkTarget target, {
    required String tenantId,
    required Uint8List audio,
    required String mimeType,
    required Duration duration,
  }) async {
    uploads.add(('voice', tenantId, audio.length, duration));
    _add(target, _make(RemarkKind.voice, path: '$tenantId/remarks/v.m4a', duration: duration));
  }

  @override
  Future<void> addPhoto(RemarkTarget target, {required String tenantId, required Uint8List jpeg}) async {
    uploads.add(('photo', tenantId, jpeg.length, null));
    _add(target, _make(RemarkKind.photo, path: '$tenantId/remarks/p.jpg'));
  }

  @override
  Future<void> archive(String remarkId) async {
    archived.add(remarkId);
    for (final list in byTarget.values) {
      list.removeWhere((r) => r.id == remarkId);
    }
  }
}

class FakeVoiceRecorder implements VoiceRecorder {
  bool permission = true;
  bool recording = false;
  Duration next = const Duration(seconds: 4);
  int cancels = 0;

  @override
  Future<bool> ensurePermission() async => permission;

  @override
  Future<void> start() async => recording = true;

  @override
  Future<RecordedAudio?> stop() async {
    recording = false;
    return RecordedAudio(bytes: Uint8List.fromList(List.filled(32, 1)), mimeType: 'audio/mp4', duration: next);
  }

  @override
  Future<void> cancel() async {
    recording = false;
    cancels++;
  }
}

class FakeVoicePlayer implements VoicePlayer {
  final played = <String>[];
  final _now = StreamController<String?>.broadcast();

  @override
  Stream<String?> get nowPlaying => _now.stream;

  @override
  Future<void> play(String id, String url) async {
    played.add(url);
    _now.add(id);
  }

  @override
  Future<void> stop() async => _now.add(null);
}
