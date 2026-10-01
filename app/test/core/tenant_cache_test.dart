import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/core/core.dart';

void main() {
  test('reads nothing before a session is bound', () {
    expect(TenantCache().read<String>('product_1024'), isNull);
    expect(() => TenantCache().write('x', 1), throwsStateError);
  });

  test('same key in two tenants never collides', () {
    final cache = TenantCache()..bind(tenantId: 'A', userId: 'u1');
    cache.write('product_1024', 'A-data');
    cache.bind(tenantId: 'B', userId: 'u2');
    expect(cache.read<String>('product_1024'), isNull, reason: 'switching identity wipes the cache');
    cache.write('product_1024', 'B-data');
    expect(cache.read<String>('product_1024'), 'B-data');
  });

  test('clear on sign-out drops everything', () {
    final cache = TenantCache()..bind(tenantId: 'A', userId: 'u1');
    cache.write('k', 'v');
    cache.clear();
    expect(cache.isBound, isFalse);
    expect(cache.length, 0);
    expect(cache.read<String>('k'), isNull);
  });

  test('bounded LRU evicts least recently used', () {
    final cache = TenantCache(maxEntries: 2)..bind(tenantId: 'A', userId: 'u');
    cache
      ..write('a', 1)
      ..write('b', 2);
    expect(cache.read<int>('a'), 1); // a is now most recent
    cache.write('c', 3);
    expect(cache.read<int>('b'), isNull);
    expect(cache.read<int>('a'), 1);
    expect(cache.read<int>('c'), 3);
  });

  test('re-binding the same identity keeps data', () {
    final cache = TenantCache()..bind(tenantId: 'A', userId: 'u');
    cache.write('k', 'v');
    cache.bind(tenantId: 'A', userId: 'u');
    expect(cache.read<String>('k'), 'v');
  });
}
