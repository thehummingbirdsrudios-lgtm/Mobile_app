import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/core/core.dart';
import 'package:vepari/features/search/search.dart';
import 'package:vepari/features/search/search_adapters.dart';

import '../../support/fakes.dart';

class _Transport implements RpcTransport {
  _Transport(this.response);

  final Object? response;
  final calls = <(String, Map<String, Object?>?)>[];

  @override
  Future<Object?> rpc(String function, Map<String, Object?>? params) async {
    calls.add((function, params));
    return response;
  }
}

void main() {
  group('SearchRepositoryImpl', () {
    late _Transport transport;
    late SearchRepositoryImpl repo;

    void build(Object? response) {
      transport = _Transport(response);
      repo = SearchRepositoryImpl(
        SearchApi(
          ApiClient(
            transport: transport,
            logger: AppLogger(minLevel: LogLevel.error, sinks: const []),
          ),
        ),
        RecentSearchStore(MemoryPreferenceStore()),
      );
    }

    test('groups rows by kind and skips kinds this app does not know', () async {
      build([
        {'kind': 'product', 'id': 'p1', 'title': '1024', 'subtitle': 'Kundan Set', 'rank': 3},
        {'kind': 'customer', 'id': 'c1', 'title': 'Patel', 'subtitle': null, 'rank': 2},
        {'kind': 'order', 'id': 'o1', 'title': '1045', 'subtitle': 'Patel', 'rank': 3},
        {'kind': 'invoice', 'id': 'x1', 'title': 'future kind', 'subtitle': null, 'rank': 1},
      ]);
      final r = await repo.search(' kun ');
      expect(r.query, 'kun');
      expect(r.products.single.title, '1024');
      expect(r.customers.single.subtitle, isNull);
      expect(r.orders.single.id, 'o1');
      expect(transport.calls.single.$1, 'search_all');
      expect(transport.calls.single.$2, {'p_query': 'kun', 'p_limit': 8});
    });

    test('blank query never calls the server', () async {
      build(const []);
      expect((await repo.search('   ')).isEmpty, isTrue);
      expect(transport.calls, isEmpty);
    });

    test('long input is clipped to the server limit', () async {
      build(const []);
      await repo.search('x' * 100);
      expect((transport.calls.single.$2!['p_query']! as String).length, maxSearchQueryLength);
    });

    test('a malformed row is an invalid response, not a crash', () async {
      build([
        {'kind': 'product', 'title': 'no id'},
      ]);
      await expectLater(
        repo.search('a'),
        throwsA(isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.invalidResponse)),
      );
    });
  });

  group('RecentSearchStore', () {
    test('newest first, case-insensitive de-duplication, bounded', () async {
      final store = RecentSearchStore(MemoryPreferenceStore(), maxEntries: 3);
      for (final q in ['patel', 'kundan', 'PATEL', '1045', 'jhumka']) {
        await store.add('t-a/u-1', q);
      }
      expect(store.read('t-a/u-1'), ['jhumka', '1045', 'PATEL']);
    });

    test('history is per identity', () async {
      final prefs = MemoryPreferenceStore();
      final store = RecentSearchStore(prefs);
      await store.add('t-a/u-owner', 'Secret customer');
      expect(store.read('t-b/u-other'), isEmpty);
      expect(store.read('t-a/u-staff'), isEmpty);
      await store.clear('t-a/u-owner');
      expect(store.read('t-a/u-owner'), isEmpty);
    });

    test('corrupted stored value reads as empty', () {
      final prefs = MemoryPreferenceStore()..values['search.recent.t/u'] = '{not json';
      expect(RecentSearchStore(prefs).read('t/u'), isEmpty);
    });
  });
}
