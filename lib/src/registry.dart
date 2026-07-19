/// A read-only registry mapping acronyms to their descriptions.
///
/// Keys are normalized at construction time. When [caseInsensitive] is `true`
/// (the default), all keys are stored uppercased and lookups normalize the
/// query key the same way. When `false`, keys are stored and matched
/// exactly as provided.
///
/// Example:
/// ```dart
/// final reg = AcronymRegistry({
///   'SDK': 'Software Development Kit',
///   'api': 'Application Programming Interface',
/// });
///
/// // Case-insensitive by default:
/// print(reg.contains('sdk')); // true
/// print(reg.descriptionOf('Api')); // "Application Programming Interface"
/// ```
class AcronymRegistry {
  /// Creates a registry from [entries].
  ///
  /// When [caseInsensitive] is `true`, all keys in [entries] are converted to
  /// upper case during construction. When `false`, keys are kept as-is. The
  /// entries are defensively copied, so later changes to the source map cannot
  /// affect the registry.
  AcronymRegistry(Map<String, String> entries, {this.caseInsensitive = true})
    : _entries = Map<String, String>.unmodifiable(
        _normalize(entries.entries, caseInsensitive: caseInsensitive),
      );

  /// Creates a registry from an iterable of acronym-description entries.
  factory AcronymRegistry.fromEntries(
    Iterable<MapEntry<String, String>> entries, {
    bool caseInsensitive = true,
  }) => AcronymRegistry(
    Map<String, String>.fromEntries(entries),
    caseInsensitive: caseInsensitive,
  );

  /// Creates an empty registry.
  factory AcronymRegistry.empty({bool caseInsensitive = true}) =>
      AcronymRegistry(const {}, caseInsensitive: caseInsensitive);

  /// Whether lookups are case-insensitive.
  ///
  /// If `true`, [contains] and [descriptionOf] normalize query keys to upper
  /// case before matching.
  final bool caseInsensitive;

  final Map<String, String> _entries;

  /// An unmodifiable view of the normalized registry entries.
  ///
  /// Keys are uppercased when [caseInsensitive] is `true`.
  Map<String, String> get entries => _entries;

  /// The number of registered acronyms.
  int get length => _entries.length;

  /// Whether the registry has no entries.
  bool get isEmpty => _entries.isEmpty;

  /// Whether the registry has at least one entry.
  bool get isNotEmpty => _entries.isNotEmpty;

  /// Returns whether the registry has an entry for [key].
  ///
  /// If [caseInsensitive] is `true`, [key] is matched in a case-insensitive
  /// manner (by uppercasing it).
  bool contains(String key) => _entries.containsKey(_normalizeKey(key));

  /// Returns whether the registry has an entry for [key].
  ///
  /// This conventional map-style alias is equivalent to [contains].
  bool containsKey(String key) => contains(key);

  /// Returns the description associated with [key], or `null` if absent.
  ///
  /// If [caseInsensitive] is `true`, [key] is uppercased before lookup.
  String? descriptionOf(String key) => _entries[_normalizeKey(key)];

  /// Returns the description associated with [key], or `null` if absent.
  String? operator [](String key) => descriptionOf(key);

  String _normalizeKey(String key) => caseInsensitive ? key.toUpperCase() : key;

  static Map<String, String> _normalize(
    Iterable<MapEntry<String, String>> entries, {
    required bool caseInsensitive,
  }) {
    final normalized = <String, String>{};
    for (final MapEntry(:key, :value) in entries) {
      normalized[caseInsensitive ? key.toUpperCase() : key] = value;
    }
    return normalized;
  }
}
