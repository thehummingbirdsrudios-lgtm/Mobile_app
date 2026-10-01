import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/core/core.dart';

void main() {
  test('loads pages until the cursor runs out', () async {
    final states = <PagedState<int, int>>[];
    final p = Paginator<int, int>(
      (cursor) async => PageResult([
        for (var i = cursor ?? 0; i < (cursor ?? 0) + 3; i++) i,
      ], next: (cursor ?? 0) + 3 < 7 ? (cursor ?? 0) + 3 : null),
      states.add,
    );
    await p.refresh();
    await p.loadMore();
    await p.loadMore();
    await p.loadMore(); // no-op: no more pages
    expect(p.state.items, [0, 1, 2, 3, 4, 5, 6, 7, 8]);
    expect(p.state.hasMore, isFalse);
    expect(states.first.isLoadingFirst, isTrue);
  });

  test('overlapping loadMore calls fetch once', () async {
    var calls = 0;
    final gate = Completer<void>();
    final p = Paginator<int, int>((cursor) async {
      calls++;
      if (cursor != null) await gate.future;
      return const PageResult([1], next: 1);
    }, (_) {});
    await p.refresh();
    final a = p.loadMore();
    final b = p.loadMore();
    gate.complete();
    await Future.wait([a, b]);
    expect(calls, 2);
  });

  test('a refresh discards a stale in-flight page', () async {
    final slow = Completer<PageResult<String, int>>();
    var first = true;
    final p = Paginator<String, int>((cursor) {
      if (first) {
        first = false;
        return slow.future;
      }
      return Future.value(const PageResult(['fresh']));
    }, (_) {});
    final stale = p.refresh();
    await p.refresh();
    slow.complete(const PageResult(['stale']));
    await stale;
    expect(p.state.items, ['fresh']);
  });

  test('failure is kept, then retry recovers', () async {
    var fail = true;
    final p = Paginator<int, int>((cursor) async {
      if (fail) throw const AppFailure(FailureKind.network);
      return const PageResult([1, 2]);
    }, (_) {});
    await p.refresh();
    expect(p.state.failure?.kind, FailureKind.network);
    expect(p.state.isEmpty, isFalse);
    fail = false;
    await p.retry();
    expect(p.state.items, [1, 2]);
    expect(p.state.failure, isNull);
  });
}
