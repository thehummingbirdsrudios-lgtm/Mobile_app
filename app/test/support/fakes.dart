import 'dart:async';
import 'dart:typed_data';

import 'package:vepari/core/core.dart';
import 'package:vepari/features/auth/auth.dart';
import 'package:vepari/features/catalogue/catalogue.dart';
import 'package:vepari/features/catalogue/domain/catalogue.dart'
    show CatalogueCursor, PhotoUpload, ProductDraft, ProductPrivate;
import 'package:vepari/features/customers/customers.dart';
import 'package:vepari/features/customers/domain/customers.dart' show CustomerCursor, CustomerDraft;
import 'package:vepari/features/dashboard/dashboard.dart';
import 'package:vepari/features/search/search.dart';
import 'package:vepari/features/settings/settings.dart';

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
