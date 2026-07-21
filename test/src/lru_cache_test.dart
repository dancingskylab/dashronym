import 'package:dashronym/src/lru_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LruCache evicts least recently used entries', () {
    final cache = LruCache<int, String>(capacity: 2);
    cache.put(1, 'one');
    cache.put(2, 'two');

    expect(cache.get(1), 'one'); // mark 1 as most recent
    cache.put(3, 'three'); // should evict key 2

    expect(cache.get(2), isNull);
    expect(cache.get(1), 'one');
    expect(cache.get(3), 'three');
  });

  test('LruCache returns null when key missing', () {
    final cache = LruCache<int, String>(capacity: 1);
    expect(cache.get(42), isNull);
  });

  test('LruCache retains and promotes cached null values', () {
    final cache = LruCache<int, String?>(capacity: 2);
    cache.put(1, null);
    cache.put(2, 'two');

    expect(cache.get(1), isNull);
    expect(cache.containsKey(1), isTrue);

    cache.put(3, 'three');

    expect(cache.containsKey(1), isTrue);
    expect(cache.containsKey(2), isFalse);
    expect(cache.length, 2);
  });

  test('updating a key promotes it to most recently used', () {
    final cache = LruCache<int, String>(capacity: 2);
    cache.put(1, 'one');
    cache.put(2, 'two');

    cache.put(1, 'updated');
    cache.put(3, 'three');

    expect(cache.get(1), 'updated');
    expect(cache.containsKey(2), isFalse);
  });

  test('LruCache rejects non-positive capacity in release builds', () {
    expect(() => LruCache<int, int>(capacity: 0), throwsArgumentError);
    expect(() => LruCache<int, int>(capacity: -1), throwsArgumentError);
  });
}
