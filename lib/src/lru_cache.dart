/// A tiny, generic least-recently-used (LRU) cache.
///
/// Stores up to [capacity] key–value pairs. When inserting a new key while the
/// cache is full, the least-recently-used entry is evicted. A successful [get]
/// marks that entry as most-recently-used (MRU).
///
/// This implementation uses a `LinkedHashMap` (the default for `{}`) to preserve
/// insertion order. Calling [get] or [put] removes and re-inserts an existing
/// key to move it to the end (MRU position).
///
/// Example:
/// ```dart
/// final cache = Lru<String, int>(capacity: 2);
/// cache.put('a', 1);   // cache: [a]
/// cache.put('b', 2);   // cache: [a, b]
/// cache.get('a');      // marks 'a' as MRU; order ~ [b, a]
/// cache.put('c', 3);   // evicts 'b' (LRU), cache: [a, c]
/// print(cache.get('b')); // null
/// print(cache.get('a')); // 1
/// ```
///
/// Notes:
/// * [capacity] must be greater than zero.
/// * [get] returns `null` when [key] is absent.
/// * When `V` is nullable, use [containsKey] to distinguish a cached `null`
///   from a cache miss.
/// * Not thread-safe; synchronize externally if used across isolates.
class Lru<K, V> {
  /// Creates an LRU cache that can hold up to [capacity] entries.
  ///
  /// The [capacity] must be greater than zero.
  Lru({required int capacity}) : capacity = _validatedCapacity(capacity);

  /// Maximum number of entries the cache will hold.
  final int capacity;

  // Uses LinkedHashMap semantics to track insertion order.
  final _map = <K, V>{};

  /// The number of entries currently in the cache.
  int get length => _map.length;

  /// Whether [key] is currently cached.
  ///
  /// This is particularly useful when `V` is nullable because [get] returns
  /// `null` for both a cached `null` and a cache miss.
  bool containsKey(K key) => _map.containsKey(key);

  /// Returns the value for [key], or `null` if absent, and marks it MRU if found.
  ///
  /// On a hit, the entry's recency is updated by removing and re-inserting it.
  V? get(K key) {
    if (!_map.containsKey(key)) return null;

    final value = _map[key] as V;
    _map.remove(key);
    _map[key] = value;
    return value;
  }

  /// Inserts or updates [value] for [key], evicting the LRU entry if needed.
  ///
  /// If [key] is new and the cache is at [capacity], the least-recently-used
  /// entry is removed before inserting the new one.
  ///
  /// If [key] already exists, its value is updated and it becomes the
  /// most-recently-used entry.
  void put(K key, V value) {
    final existed = _map.containsKey(key);
    if (existed) _map.remove(key);
    if (!existed && _map.length >= capacity) {
      _map.remove(_map.keys.first);
    }
    _map[key] = value;
  }

  static int _validatedCapacity(int capacity) {
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be greater than 0');
    }
    return capacity;
  }
}
