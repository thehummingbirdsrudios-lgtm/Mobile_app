import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../../../core/errors/app_failure.dart';
import '../../auth/auth.dart';
import '../domain/search.dart';

/// Overridden at the composition root and in tests.
final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => throw UnimplementedError('searchRepositoryProvider must be overridden'),
);

@immutable
class SearchState {
  const SearchState({this.query = '', this.results, this.isLoading = false, this.failure, this.recent = const []});

  /// What the user is searching for now ('' shows recent searches).
  final String query;

  /// Latest results; while a newer query loads these may be for the previous
  /// query (kept on screen so the list does not flash empty).
  final SearchResults? results;
  final bool isLoading;
  final AppFailure? failure;
  final List<String> recent;
}

final searchControllerProvider = NotifierProvider.autoDispose<SearchController, SearchState>(SearchController.new);

class SearchController extends Notifier<SearchState> {
  int _generation = 0;

  String? get _scope {
    final s = ref.read(currentSessionProvider);
    return s == null ? null : '${s.tenantId}/${s.userId}';
  }

  SearchRepository get _repo => ref.read(searchRepositoryProvider);

  List<String> _readRecent() {
    final scope = _scope;
    return scope == null ? const [] : _repo.recent(scope);
  }

  @override
  SearchState build() {
    // Another identity must never see this identity's results or history.
    ref.watch(currentSessionProvider.select((s) => (s?.tenantId, s?.userId)));
    _generation++;
    return SearchState(recent: _readRecent());
  }

  /// Runs a search. Responses that arrive after a newer query are dropped.
  Future<void> setQuery(String raw) async {
    final q = raw.trim();
    final generation = ++_generation;
    if (q.isEmpty) {
      state = SearchState(recent: _readRecent());
      return;
    }
    state = SearchState(query: q, results: state.results, isLoading: true, recent: state.recent);
    try {
      final results = await _repo.search(q);
      if (!ref.mounted || generation != _generation) return;
      state = SearchState(query: q, results: results, recent: state.recent);
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = SearchState(query: q, failure: AppFailure.from(error), recent: state.recent);
    }
  }

  Future<void> retry() => setQuery(state.query);

  /// Saves [query] to recent searches (called when a result is opened).
  Future<void> remember(String query) async {
    final scope = _scope;
    if (scope == null || query.trim().isEmpty) return;
    await _repo.remember(scope, query);
  }

  Future<void> clearRecent() async {
    final scope = _scope;
    if (scope == null) return;
    await _repo.clearRecent(scope);
    if (ref.mounted) state = SearchState(query: state.query, results: state.results, recent: const []);
  }
}
