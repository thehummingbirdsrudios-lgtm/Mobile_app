import 'package:flutter/foundation.dart';

import '../errors/app_failure.dart';

/// One page from a keyset-paginated source.
@immutable
class PageResult<T, C> {
  const PageResult(this.items, {this.next});

  final List<T> items;

  /// Cursor for the next page; null when this was the last page.
  final C? next;
}

/// Immutable state of an infinite list.
@immutable
class PagedState<T, C> {
  const PagedState({
    this.items = const [],
    this.cursor,
    this.hasMore = true,
    this.isLoadingFirst = true,
    this.isLoadingMore = false,
    this.failure,
  });

  final List<T> items;
  final C? cursor;
  final bool hasMore;
  final bool isLoadingFirst;
  final bool isLoadingMore;

  /// Last failure. With items present it is shown inline (retry at the end).
  final AppFailure? failure;

  bool get isEmpty => !isLoadingFirst && failure == null && items.isEmpty;

  PagedState<T, C> copyWith({
    List<T>? items,
    C? cursor,
    bool? hasMore,
    bool? isLoadingFirst,
    bool? isLoadingMore,
    AppFailure? failure,
    bool clearFailure = false,
  }) => PagedState(
    items: items ?? this.items,
    cursor: cursor ?? this.cursor,
    hasMore: hasMore ?? this.hasMore,
    isLoadingFirst: isLoadingFirst ?? this.isLoadingFirst,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    failure: clearFailure ? null : (failure ?? this.failure),
  );
}

/// Drives a [PagedState] from a page loader. Guards against overlapping
/// loads and stale responses (a refresh discards an in-flight older page).
class Paginator<T, C> {
  Paginator(this._load, this._emit);

  final Future<PageResult<T, C>> Function(C? cursor) _load;
  final void Function(PagedState<T, C> state) _emit;
  PagedState<T, C> _state = PagedState<T, C>();
  int _generation = 0;

  PagedState<T, C> get state => _state;

  void _set(PagedState<T, C> next) {
    _state = next;
    _emit(next);
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    _set(PagedState<T, C>(items: _state.items, isLoadingFirst: _state.items.isEmpty));
    try {
      final page = await _load(null);
      if (generation != _generation) return;
      _set(PagedState(items: page.items, cursor: page.next, hasMore: page.next != null, isLoadingFirst: false));
    } catch (error) {
      if (generation != _generation) return;
      _set(_state.copyWith(isLoadingFirst: false, failure: AppFailure.from(error)));
    }
  }

  Future<void> loadMore() async {
    if (_state.isLoadingFirst || _state.isLoadingMore || !_state.hasMore || _state.failure != null) return;
    final generation = _generation;
    _set(_state.copyWith(isLoadingMore: true));
    try {
      final page = await _load(_state.cursor);
      if (generation != _generation) return;
      _set(
        PagedState(
          items: [..._state.items, ...page.items],
          cursor: page.next,
          hasMore: page.next != null,
          isLoadingFirst: false,
        ),
      );
    } catch (error) {
      if (generation != _generation) return;
      _set(_state.copyWith(isLoadingMore: false, failure: AppFailure.from(error)));
    }
  }

  /// Retry after a failure (first page or next page).
  Future<void> retry() {
    if (_state.items.isEmpty) return refresh();
    _set(_state.copyWith(clearFailure: true));
    return loadMore();
  }
}
