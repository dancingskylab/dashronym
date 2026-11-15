/// A read-only registry mapping acronyms to their descriptions.
///
/// Keys are normalized at construction time. When [caseInsensitive] is `true`
/// (the default), all keys are stored uppercased and lookups normalize the
/// query key the same way. When `false`, keys are stored and matched exactly as
/// provided.
///
/// Example:
/// ```dart
/// final registry = DashronymRegistry({
///   'SDK': 'Software Development Kit',
///   'api': 'Application Programming Interface',
/// });
///
/// print(registry.contains('sdk')); // true
/// print(registry.descriptionOf('Api'));
/// // Application Programming Interface
/// ```
class DashronymRegistry {
  /// Creates a registry from an acronym-to-description map.
  ///
  /// When [caseInsensitive] is `true`, all keys in [entries] are converted to
  /// upper case during construction. When `false`, keys are kept as-is. The
  /// entries are defensively copied, so later changes to the source map cannot
  /// affect the registry.
  ///
  /// If multiple keys normalize to the same value, the later entry wins.
  DashronymRegistry(
    Map<String, String> entries, {
    bool caseInsensitive = true,
  }) : this._(
         caseInsensitive: caseInsensitive,
         entries: _normalizeEntries(
           entries.entries,
           caseInsensitive: caseInsensitive,
         ),
       );

  DashronymRegistry._({
    required this.caseInsensitive,
    required Map<String, String> entries,
  }) : _entries = Map<String, String>.unmodifiableOf(entries);

  /// Creates a registry from an iterable of acronym-description entries.
  ///
  /// If multiple keys normalize to the same value, the later entry wins.
  factory DashronymRegistry.fromMapEntries(
    Iterable<MapEntry<String, String>> entries, {
    bool caseInsensitive = true,
  }) => DashronymRegistry._(
    caseInsensitive: caseInsensitive,
    entries: _normalizeEntries(
      entries,
      caseInsensitive: caseInsensitive,
    ),
  );

  /// Creates an empty registry.
  factory DashronymRegistry.empty({bool caseInsensitive = true}) =>
      DashronymRegistry(const {}, caseInsensitive: caseInsensitive);

  /// Whether lookups are case-insensitive.
  ///
  /// If `true`, [contains] and [descriptionOf] normalize query keys to upper
  /// case before matching.
  final bool caseInsensitive;

  final Map<String, String> _entries;

  /// An unmodifiable map of normalized acronyms and descriptions.
  Map<String, String> get entries => _entries;

  /// The number of entries.
  int get length => _entries.length;

  /// Whether the registry has no entries.
  bool get isEmpty => _entries.isEmpty;

  /// Whether the registry has at least one entry.
  bool get isNotEmpty => _entries.isNotEmpty;

  /// Returns whether the registry has an entry for [key].
  bool contains(String key) => _entries.containsKey(_normalizeKey(key));

  /// Returns whether the registry has an entry for [key].
  ///
  /// This conventional map-style alias is equivalent to [contains].
  bool containsKey(String key) => contains(key);

  /// Returns the description associated with [key], or `null`.
  String? descriptionOf(String key) => _entries[_normalizeKey(key)];

  /// Returns the description associated with [key], or `null`.
  String? operator [](String key) => descriptionOf(key);

  String _normalizeKey(String key) =>
      _normalize(key, caseInsensitive: caseInsensitive);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashronymRegistry &&
          other.caseInsensitive == caseInsensitive &&
          _mapsEqual(other._entries, _entries);

  @override
  int get hashCode => Object.hash(
    caseInsensitive,
    Object.hashAllUnordered(
      _entries.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );

  static Map<String, String> _normalizeEntries(
    Iterable<MapEntry<String, String>> entries, {
    required bool caseInsensitive,
  }) {
    final normalized = <String, String>{};
    for (final MapEntry(:key, :value) in entries) {
      normalized[_normalize(key, caseInsensitive: caseInsensitive)] = value;
    }
    return normalized;
  }

  static String _normalize(
    String key, {
    required bool caseInsensitive,
  }) => caseInsensitive ? key.toUpperCase() : key;

  static bool _mapsEqual(
    Map<String, String> left,
    Map<String, String> right,
  ) =>
      left.length == right.length &&
      left.entries.every((entry) => right[entry.key] == entry.value);
}
