import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../domain/search.dart';

/// Remote data source for the `search_all` RPC (SECURITY INVOKER: RLS limits
/// results to the caller's business).
class SearchApi {
  const SearchApi(this._api);

  final ApiClient _api;

  Future<List<SearchHit>> search(String query, {required int limitPerGroup}) => _api.rpc(
    'search_all',
    params: {'p_query': query, 'p_limit': limitPerGroup},
    decode: (json) => [for (final row in (json as List? ?? const [])) ?searchHitFromJson(asJsonObject(row))],
  );
}

/// Unknown kinds (a newer server) are skipped rather than crashing.
SearchHit? searchHitFromJson(Map<String, dynamic> json) {
  final kind = SearchKind.values.where((k) => k.name == json['kind']).firstOrNull;
  if (kind == null) return null;
  return SearchHit(
    kind: kind,
    id: json.requireString('id'),
    title: json.requireString('title'),
    subtitle: json.optionalString('subtitle'),
  );
}
