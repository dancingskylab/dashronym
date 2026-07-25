/// Parsing and matching configuration for dashronyms.
///
/// Controls which acronyms are considered matches, which marker pairs are
/// honored, and how bare uppercase words are interpreted.
///
/// Matching modes:
/// * Marker-based: detects registered terms wrapped by accepted pairs from
///   [acceptMarkers] (e.g., `"()"` recognizes `(SDK)`, `(C++)`, and
///   `(OAuth)`). Explicit terms may contain punctuation or mixed case, but
///   never an embedded line break.
/// * Bare acronyms: when [enableBareAcronyms] is `true`, matches ALL-CAPS
///   ASCII words within [minLen]…[maxLen].
///
/// Invariants:
/// * [minLen] > 0
/// * [maxLen] >= [minLen]
/// * [acceptMarkers] contains at most [maxAcceptedMarkerPairs] pairs
///
/// Example:
/// ```dart
/// final config = DashronymConfig.withMarkers(
///   enableBareAcronyms: true,
///   minLen: 2,
///   maxLen: 10,
///   acceptMarkers: ['()', '""', "''"], // (ABC), "ABC", 'ABC'
/// );
/// ```
class DashronymConfig {
  /// The marker pairs used by the default constructor.
  static const List<String> defaultAcceptMarkers = ['()', "''", '""'];

  /// The maximum number of marker pairs accepted by one configuration.
  static const int maxAcceptedMarkerPairs = 16;

  /// Creates a configuration for acronym parsing and matching.
  ///
  /// By default, both marker-wrapped acronyms and bare ALL-CAPS words are
  /// matched.
  ///
  /// Validation is deferred until [validate] is called or the configuration is
  /// consumed by a parser. This keeps the constructor `const` while still
  /// enforcing the invariants in release builds.
  const DashronymConfig({
    this.enableBareAcronyms = true,
    this.minLen = 2,
    this.maxLen = 10,
  }) : _acceptMarkers = defaultAcceptMarkers;

  /// Creates a validated configuration with custom marker pairs.
  ///
  /// The supplied iterable is defensively copied. Subsequent changes to the
  /// source collection cannot alter this configuration or its value equality.
  factory DashronymConfig.withMarkers({
    bool enableBareAcronyms = true,
    int minLen = 2,
    int maxLen = 10,
    required Iterable<String> acceptMarkers,
  }) {
    final config = DashronymConfig._(
      enableBareAcronyms: enableBareAcronyms,
      minLen: minLen,
      maxLen: maxLen,
      acceptMarkers: List<String>.unmodifiable(acceptMarkers),
    );
    config.validate();
    return config;
  }

  const DashronymConfig._({
    required this.enableBareAcronyms,
    required this.minLen,
    required this.maxLen,
    required List<String> acceptMarkers,
  }) : _acceptMarkers = acceptMarkers;

  /// Whether bare ALL-CAPS words are matched against the registry.
  ///
  /// When `true`, tokens like `SDK` or `API` (length-bounded by [minLen] and
  /// [maxLen]) are considered even without marker characters.
  final bool enableBareAcronyms;

  /// Minimum allowed length for an explicit or bare acronym match.
  ///
  /// Length is measured in Unicode scalar values.
  final int minLen;

  /// Maximum allowed length for an explicit or bare acronym match.
  ///
  /// Length is measured in Unicode scalar values.
  final int maxLen;

  /// Marker pairs recognized by the parser.
  ///
  /// Each string must contain exactly two characters representing the left and
  /// right markers, e.g. `"()"` for `(ABC)`, `""` for `"ABC"`, and `''` for
  /// `'ABC'`. A character means one Unicode scalar value, so non-ASCII marker
  /// pairs are supported. Pairs are treated literally by the parser.
  ///
  /// The returned list cannot be modified.
  List<String> get acceptMarkers => _acceptMarkers;

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

    if (_acceptMarkers.length > maxAcceptedMarkerPairs) {
      throw ArgumentError.value(
        _acceptMarkers.length,
        'acceptMarkers',
        'must contain at most $maxAcceptedMarkerPairs marker pairs',
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
  }) => DashronymConfig.withMarkers(
    enableBareAcronyms: enableBareAcronyms ?? this.enableBareAcronyms,
    minLen: minLen ?? this.minLen,
    maxLen: maxLen ?? this.maxLen,
    acceptMarkers: acceptMarkers ?? _acceptMarkers,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashronymConfig &&
          other.enableBareAcronyms == enableBareAcronyms &&
          other.minLen == minLen &&
          other.maxLen == maxLen &&
          _listsEqual(other._acceptMarkers, _acceptMarkers);

  @override
  int get hashCode => Object.hash(
    enableBareAcronyms,
    minLen,
    maxLen,
    Object.hashAll(_acceptMarkers),
  );

  static bool _listsEqual(List<String> left, List<String> right) =>
      left.length == right.length &&
      Iterable<int>.generate(
        left.length,
      ).every((index) => left[index] == right[index]);
}
