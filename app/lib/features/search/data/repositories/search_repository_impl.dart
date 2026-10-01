import '../../domain/search.dart';
import '../local/recent_search_store.dart';
import '../remote/search_api.dart';

class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl(this._remote, this._recent);

  final SearchApi _remote;
  final RecentSearchStore _recent;

  @override
  Future<SearchResults> search(String query, {int limitPerGroup = 8}) async {
    final q = query.trim();
    if (q.isEmpty) return SearchResults(query: q);
    final clipped = q.length > maxSearchQueryLength ? q.substring(0, maxSearchQueryLength) : q;
    return SearchResults.fromHits(q, await _remote.search(clipped, limitPerGroup: limitPerGroup));
  }

  @override
  List<String> recent(String scope) => _recent.read(scope);

  @override
  Future<void> remember(String scope, String query) => _recent.add(scope, query);

  @override
  Future<void> clearRecent(String scope) => _recent.clear(scope);
}
