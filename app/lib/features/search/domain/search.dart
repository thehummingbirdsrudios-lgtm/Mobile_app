import 'package:meta/meta.dart';

enum SearchKind { product, customer, order }

/// One result row. [title]/[subtitle] are display text chosen by the server
/// (design no + name, customer + shop/city, order no + customer).
@immutable
class SearchHit {
  const SearchHit({required this.kind, required this.id, required this.title, this.subtitle});

  final SearchKind kind;
  final String id;
  final String title;
  final String? subtitle;
}

/// Results grouped the way they are shown.
@immutable
class SearchResults {
  const SearchResults({
    required this.query,
    this.products = const [],
    this.customers = const [],
    this.orders = const [],
  });

  factory SearchResults.fromHits(String query, Iterable<SearchHit> hits) => SearchResults(
    query: query,
    products: [
      for (final h in hits)
        if (h.kind == SearchKind.product) h,
    ],
    customers: [
      for (final h in hits)
        if (h.kind == SearchKind.customer) h,
    ],
    orders: [
      for (final h in hits)
        if (h.kind == SearchKind.order) h,
    ],
  );

  final String query;
  final List<SearchHit> products;
  final List<SearchHit> customers;
  final List<SearchHit> orders;

  bool get isEmpty => products.isEmpty && customers.isEmpty && orders.isEmpty;
}

/// Server limit on query length (longer input returns nothing).
const maxSearchQueryLength = 60;

/// Search port. Implementations throw `AppFailure`.
///
/// Recent searches are device-local and scoped to one signed-in identity
/// ([scope] = tenant/user), so another account on the same phone never sees
/// them.
abstract interface class SearchRepository {
  Future<SearchResults> search(String query, {int limitPerGroup});

  List<String> recent(String scope);

  Future<void> remember(String scope, String query);

  Future<void> clearRecent(String scope);
}
