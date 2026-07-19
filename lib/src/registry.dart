import 'dart:collection';

import 'acronym_entry.dart';

/// How [AcronymRegistry] resolves normalized canonical or alias collisions.
enum AcronymDuplicatePolicy {
  /// Reject the registry with a helpful [ArgumentError].
  reject,

  /// Keep the first complete entry and skip a later entry with any collision.
  keepFirst,

  /// Keep the later complete entry and remove every earlier conflicting entry.
  keepLast,
}

/// A read-only registry mapping acronyms and aliases to their descriptions.
///
/// Keys are normalized at construction time. When [caseInsensitive] is `true`
/// (the default), all keys are stored uppercased and lookups normalize the
/// query key the same way. When `false`, keys are stored and matched exactly as
/// provided.
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
  /// Creates a registry from the original acronym-to-description map API.
  ///
  /// When [caseInsensitive] is `true`, all keys in [entries] are converted to
  /// upper case during construction. When `false`, keys are kept as-is. The
  /// entries are defensively copied, so later changes to the source map cannot
  /// affect the registry.
  ///
  /// [duplicatePolicy] applies when distinct map keys normalize to the same
  /// lookup key. Its default preserves the historical last-value-wins behavior.
  AcronymRegistry(
    Map<String, String> entries, {
    bool caseInsensitive = true,
    AcronymDuplicatePolicy duplicatePolicy = AcronymDuplicatePolicy.keepLast,
  }) : this._(
         caseInsensitive: caseInsensitive,
         duplicatePolicy: duplicatePolicy,
         data: _buildLegacyData(
           entries.entries,
           caseInsensitive: caseInsensitive,
           duplicatePolicy: duplicatePolicy,
         ),
       );

  AcronymRegistry._({
    required this.caseInsensitive,
    required this.duplicatePolicy,
    required _RegistryData data,
  }) : _entries = data.descriptions,
       _lookupTerms = data.lookupDescriptions,
       _entryLookup = data.lookup,
       richEntries = data.richEntries;

  /// Creates a rich registry whose aliases resolve to their canonical entries.
  ///
  /// Duplicate handling is atomic per entry: [AcronymDuplicatePolicy.keepFirst]
  /// skips an incoming entry if any of its lookup terms collide, while
  /// [AcronymDuplicatePolicy.keepLast] removes complete earlier entries
  /// involved in a collision before adding the incoming entry.
  factory AcronymRegistry.fromAcronymEntries(
    Iterable<AcronymEntry> entries, {
    bool caseInsensitive = true,
    AcronymDuplicatePolicy duplicatePolicy = AcronymDuplicatePolicy.reject,
  }) => AcronymRegistry._(
    caseInsensitive: caseInsensitive,
    duplicatePolicy: duplicatePolicy,
    data: _buildRichData(
      entries,
      caseInsensitive: caseInsensitive,
      duplicatePolicy: duplicatePolicy,
    ),
  );

  /// Creates a registry from an iterable of acronym-description entries.
  factory AcronymRegistry.fromEntries(
    Iterable<MapEntry<String, String>> entries, {
    bool caseInsensitive = true,
    AcronymDuplicatePolicy duplicatePolicy = AcronymDuplicatePolicy.keepLast,
  }) => AcronymRegistry._(
    caseInsensitive: caseInsensitive,
    duplicatePolicy: duplicatePolicy,
    data: _buildLegacyData(
      entries,
      caseInsensitive: caseInsensitive,
      duplicatePolicy: duplicatePolicy,
    ),
  );

  /// Creates an empty registry.
  factory AcronymRegistry.empty({bool caseInsensitive = true}) =>
      AcronymRegistry(const {}, caseInsensitive: caseInsensitive);

  /// Whether lookups are case-insensitive.
  ///
  /// If `true`, [contains], [descriptionOf], and [entryOf] normalize query keys
  /// to upper case before matching.
  final bool caseInsensitive;

  /// The duplicate behavior used while constructing this registry.
  final AcronymDuplicatePolicy duplicatePolicy;

  final Map<String, String> _entries;
  final Map<String, String> _lookupTerms;
  final Map<String, AcronymEntry> _entryLookup;

  /// An unmodifiable map of normalized canonical acronyms and descriptions.
  ///
  /// Aliases are intentionally excluded to preserve the original collection
  /// semantics. Use [lookupTerms] when every searchable term is needed.
  Map<String, String> get entries => _entries;

  /// An unmodifiable map of every normalized canonical and alias lookup term.
  Map<String, String> get lookupTerms => _lookupTerms;

  /// The number of canonical and alias lookup terms.
  int get lookupTermCount => _lookupTerms.length;

  /// The unique retained rich entries, in deterministic construction order.
  ///
  /// Alias terms appear in [lookupTerms] but do not duplicate values here.
  final List<AcronymEntry> richEntries;

  /// The number of canonical entries.
  int get length => _entries.length;

  /// Whether the registry has no canonical entries.
  bool get isEmpty => _entries.isEmpty;

  /// Whether the registry has at least one canonical entry.
  bool get isNotEmpty => _entries.isNotEmpty;

  /// Returns whether the registry has an entry for [key].
  bool contains(String key) => _lookupTerms.containsKey(_normalizeKey(key));

  /// Returns whether the registry has an entry for [key].
  ///
  /// This conventional map-style alias is equivalent to [contains].
  bool containsKey(String key) => contains(key);

  /// Returns the display description associated with [key], or `null`.
  String? descriptionOf(String key) => _lookupTerms[_normalizeKey(key)];

  /// Returns the rich entry associated with a canonical term or alias.
  AcronymEntry? entryOf(String key) => _entryLookup[_normalizeKey(key)];

  /// Returns the display description associated with [key], or `null`.
  String? operator [](String key) => descriptionOf(key);

  String _normalizeKey(String key) =>
      _normalize(key, caseInsensitive: caseInsensitive);

  static _RegistryData _buildLegacyData(
    Iterable<MapEntry<String, String>> entries, {
    required bool caseInsensitive,
    required AcronymDuplicatePolicy duplicatePolicy,
  }) {
    final descriptions = <String, String>{};
    final lookup = <String, AcronymEntry>{};
    final richEntries = <String, AcronymEntry>{};

    for (final MapEntry(:key, :value) in entries) {
      final normalized = _normalize(
        key,
        caseInsensitive: caseInsensitive,
      );
      if (descriptions.containsKey(normalized)) {
        switch (duplicatePolicy) {
          case AcronymDuplicatePolicy.reject:
            throw ArgumentError.value(
              key,
              'entries',
              'lookup term "$key" conflicts after normalization',
            );
          case AcronymDuplicatePolicy.keepFirst:
            continue;
          case AcronymDuplicatePolicy.keepLast:
            lookup.remove(normalized);
            richEntries.remove(normalized);
        }
      }

      descriptions[normalized] = value;
      try {
        final richEntry = AcronymEntry(acronym: key, expansion: value);
        lookup[normalized] = richEntry;
        richEntries[normalized] = richEntry;
      } on ArgumentError {
        // Legacy string maps historically accept blank and whitespace values.
        // Preserve their exact string behavior without manufacturing an
        // invalid rich model.
      }
    }

    final frozenDescriptions = Map<String, String>.unmodifiable(descriptions);
    return _RegistryData(
      descriptions: frozenDescriptions,
      lookupDescriptions: frozenDescriptions,
      lookup: Map<String, AcronymEntry>.unmodifiable(lookup),
      richEntries: List<AcronymEntry>.unmodifiable(richEntries.values),
    );
  }

  static _RegistryData _buildRichData(
    Iterable<AcronymEntry> source, {
    required bool caseInsensitive,
    required AcronymDuplicatePolicy duplicatePolicy,
  }) {
    final lookup = <String, AcronymEntry>{};
    final canonicalEntries = <String, AcronymEntry>{};
    final canonicalDescriptions = <String, String>{};

    for (final entry in source) {
      final seenTerms = <String>{};
      final terms = <({String raw, String normalized})>[
        for (final raw in [entry.acronym, ...entry.aliases])
          if (seenTerms.add(
            _normalize(raw, caseInsensitive: caseInsensitive),
          ))
            (
              raw: raw,
              normalized: _normalize(
                raw,
                caseInsensitive: caseInsensitive,
              ),
            ),
      ];
      final collisions = [
        for (final term in terms)
          if (lookup[term.normalized] case final AcronymEntry owner)
            (term: term, owner: owner),
      ];

      if (collisions.isNotEmpty) {
        switch (duplicatePolicy) {
          case AcronymDuplicatePolicy.reject:
            final collision = collisions.first;
            throw ArgumentError.value(
              entry.acronym,
              'entries',
              'lookup term "${collision.term.raw}" conflicts with '
                  '"${collision.owner.acronym}" after normalization',
            );
          case AcronymDuplicatePolicy.keepFirst:
            continue;
          case AcronymDuplicatePolicy.keepLast:
            final displaced = HashSet<AcronymEntry>.identity()
              ..addAll(collisions.map((collision) => collision.owner));
            final displacedCanonicalKeys = [
              for (final MapEntry(:key, :value) in canonicalEntries.entries)
                if (displaced.contains(value)) key,
            ];
            lookup.removeWhere(
              (_, candidate) => displaced.contains(candidate),
            );
            for (final key in displacedCanonicalKeys) {
              canonicalEntries.remove(key);
              canonicalDescriptions.remove(key);
            }
        }
      }

      final canonicalKey = _normalize(
        entry.acronym,
        caseInsensitive: caseInsensitive,
      );
      canonicalEntries[canonicalKey] = entry;
      canonicalDescriptions[canonicalKey] = entry.displayDescription;
      for (final term in terms) {
        lookup[term.normalized] = entry;
      }
    }

    return _RegistryData(
      lookup: Map<String, AcronymEntry>.unmodifiable(lookup),
      lookupDescriptions: Map<String, String>.unmodifiable({
        for (final MapEntry(:key, :value) in lookup.entries)
          key: value.displayDescription,
      }),
      descriptions: Map<String, String>.unmodifiable(canonicalDescriptions),
      richEntries: List<AcronymEntry>.unmodifiable(canonicalEntries.values),
    );
  }

  static String _normalize(
    String key, {
    required bool caseInsensitive,
  }) => caseInsensitive ? key.toUpperCase() : key;
}

final class _RegistryData {
  const _RegistryData({
    required this.lookup,
    required this.descriptions,
    required this.lookupDescriptions,
    required this.richEntries,
  });

  final Map<String, AcronymEntry> lookup;
  final Map<String, String> descriptions;
  final Map<String, String> lookupDescriptions;
  final List<AcronymEntry> richEntries;
}
