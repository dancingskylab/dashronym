/// Parsing and matching configuration for dashronyms.
///
/// Controls which acronyms are considered matches, which marker pairs are
/// honored, and how bare uppercase words are interpreted.
///
/// Matching modes:
/// * Marker-based: detects acronyms wrapped by accepted pairs from [acceptMarkers]
///   (e.g., `"()"` recognizes `(SDK)`).
/// * Bare acronyms: when [enableBareAcronyms] is `true`, matches ALL-CAPS
///   words within [minLen]…[maxLen].
///
/// Invariants:
/// * [minLen] > 0
/// * [maxLen] >= [minLen]
///
/// Example:
/// ```dart
/// const config = DashronymConfig(
///   enableBareAcronyms: true,
///   minLen: 2,
///   maxLen: 10,
///   acceptMarkers: ['()', '""', "''"], // (ABC), "ABC", 'ABC'
/// );
/// ```
class DashronymConfig {
  /// The marker pairs recognized when [acceptMarkers] is omitted.
  static const List<String> defaultAcceptMarkers = ['()', "''", '""'];

  /// Creates a configuration for acronym parsing and matching.
  ///
  /// By default, only marker-wrapped acronyms are matched; set
  /// [enableBareAcronyms] to `true` to also consider ALL-CAPS words.
  ///
  /// Validation is deferred until [validate] is called or the configuration is
  /// consumed by a parser. This keeps the constructor `const` while still
  /// enforcing the invariants in release builds.
  ///
  /// This constructor retains the supplied marker list to preserve `const`
  /// construction. Prefer [DashronymConfig.immutable] when marker pairs come
  /// from a mutable or dynamically produced collection.
  const DashronymConfig({
    this.enableBareAcronyms = false,
    this.minLen = 2,
    this.maxLen = 10,
    List<String> acceptMarkers = defaultAcceptMarkers,
  }) : _acceptMarkers = acceptMarkers;

  /// Creates a validated configuration with a defensive marker-pair copy.
  ///
  /// Use this constructor for marker pairs loaded at runtime. Subsequent
  /// changes to the source iterable cannot alter this configuration.
  factory DashronymConfig.immutable({
    bool enableBareAcronyms = false,
    int minLen = 2,
    int maxLen = 10,
    Iterable<String> acceptMarkers = defaultAcceptMarkers,
  }) {
    final config = DashronymConfig(
      enableBareAcronyms: enableBareAcronyms,
      minLen: minLen,
      maxLen: maxLen,
      acceptMarkers: List<String>.unmodifiable(acceptMarkers),
    );
    config.validate();
    return config;
  }

  /// Whether bare ALL-CAPS words are matched against the registry.
  ///
  /// When `true`, tokens like `SDK` or `API` (length-bounded by [minLen] and
  /// [maxLen]) are considered even without marker characters.
  final bool enableBareAcronyms;

  /// Minimum allowed length for a bare acronym match.
  final int minLen;

  /// Maximum allowed length for a bare acronym match.
  final int maxLen;

  /// Marker pairs recognized by the parser.
  ///
  /// Each string must contain exactly two characters representing the left and
  /// right markers, e.g. `"()"` for `(ABC)`, `""` for `"ABC"`, and `''` for
  /// `'ABC'`. A character means one Unicode scalar value, so non-ASCII marker
  /// pairs are supported. Pairs are treated literally by the parser.
  ///
  /// The returned list cannot be modified.
  List<String> get acceptMarkers => List<String>.unmodifiable(_acceptMarkers);

  final List<String> _acceptMarkers;

  /// Verifies that this configuration can be consumed by a parser.
  ///
  /// Unlike assertions, these checks run in both debug and release builds.
  /// Throws [ArgumentError] when a length bound or marker pair is invalid.
  void validate() {
    if (minLen <= 0) {
      throw ArgumentError.value(
        minLen,
        'minLen',
        'must be greater than zero',
      );
    }
    if (maxLen < minLen) {
      throw ArgumentError.value(
        maxLen,
        'maxLen',
        'must be greater than or equal to minLen ($minLen)',
      );
    }

    for (final pair in _acceptMarkers) {
      if (pair.runes.length != 2) {
        throw ArgumentError.value(
          pair,
          'acceptMarkers',
          'each marker pair must contain exactly two Unicode scalar values',
        );
      }
    }
  }

  /// Returns a validated copy with selected values replaced.
  ///
  /// Marker pairs are defensively copied, including when [acceptMarkers] is
  /// omitted.
  DashronymConfig copyWith({
    bool? enableBareAcronyms,
    int? minLen,
    int? maxLen,
    Iterable<String>? acceptMarkers,
  }) => DashronymConfig.immutable(
    enableBareAcronyms: enableBareAcronyms ?? this.enableBareAcronyms,
    minLen: minLen ?? this.minLen,
    maxLen: maxLen ?? this.maxLen,
    acceptMarkers: acceptMarkers ?? _acceptMarkers,
  );
}
