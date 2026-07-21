import 'json_value.dart';

/// An immutable, portable glossary entry for an acronym or abbreviated term.
final class DashronymEntry {
  /// Creates a validated entry.
  ///
  /// All strings must be non-empty and free of leading or trailing whitespace.
  /// [aliases] and [tags] must not contain exact duplicates. [metadata] is
  /// defensively copied, deeply frozen, and restricted to JSON-compatible
  /// values.
  factory DashronymEntry({
    required String acronym,
    required String expansion,
    String? definition,
    Iterable<String> aliases = const [],
    Iterable<String> tags = const [],
    String? source,
    Map<String, Object?> metadata = const {},
  }) {
    final validatedAcronym = _requiredText(acronym, 'acronym');
    final validatedExpansion = _requiredText(expansion, 'expansion');
    final validatedDefinition = _optionalText(definition, 'definition');
    final validatedAliases = _stringList(
      aliases,
      'aliases',
      disallowed: validatedAcronym,
    );
    final validatedTags = _stringList(tags, 'tags');
    final validatedSource = _optionalText(source, 'source');

    return DashronymEntry._(
      acronym: validatedAcronym,
      expansion: validatedExpansion,
      definition: validatedDefinition,
      aliases: validatedAliases,
      tags: validatedTags,
      source: validatedSource,
      metadata: freezeJsonMap(metadata, path: r'$.metadata'),
    );
  }

  const DashronymEntry._({
    required this.acronym,
    required this.expansion,
    required this.definition,
    required this.aliases,
    required this.tags,
    required this.source,
    required this.metadata,
  });

  /// Decodes one strict version-1 entry JSON object.
  ///
  /// [path] is included in failures when decoding an entry nested inside a
  /// larger document.
  factory DashronymEntry.fromJson(Object? json, {String path = r'$'}) {
    final reader = JsonObjectReader.from(json, path: path)
      ..rejectUnknownKeys(const {
        'acronym',
        'expansion',
        'definition',
        'aliases',
        'tags',
        'source',
        'metadata',
      });

    final aliases = _decodeStringArray(reader, 'aliases');
    final tags = _decodeStringArray(reader, 'tags');

    try {
      return DashronymEntry(
        acronym: reader.requiredString('acronym'),
        expansion: reader.requiredString('expansion'),
        definition: reader.optionalString('definition'),
        aliases: aliases,
        tags: tags,
        source: reader.optionalString('source'),
        metadata: reader.optionalObject('metadata'),
      );
    } on ArgumentError catch (error) {
      throw FormatException('$path is invalid: ${error.message}');
    }
  }

  /// The canonical acronym or abbreviated term.
  final String acronym;

  /// The human-readable expansion of [acronym].
  final String expansion;

  /// An optional longer explanation.
  final String? definition;

  /// Alternative lookup terms that resolve to this entry.
  final List<String> aliases;

  /// Search, filtering, or catalog classification tags.
  final List<String> tags;

  /// An optional source URL, citation, or source identifier.
  final String? source;

  /// Deeply immutable application-specific JSON data.
  final Map<String, Object?> metadata;

  /// A single string suitable for the package's existing tooltip API.
  ///
  /// When a longer [definition] exists it follows the expansion with an em
  /// dash. Otherwise this is exactly [expansion].
  String get displayDescription => switch (definition) {
    final String definition => '$expansion — $definition',
    null => expansion,
  };

  /// Converts this entry into a deterministic JSON-compatible object.
  Map<String, Object?> toJson() => {
    'acronym': acronym,
    'expansion': expansion,
    if (definition case final String definition) 'definition': definition,
    'aliases': aliases,
    'tags': tags,
    if (source case final String source) 'source': source,
    'metadata': metadata,
  };

  /// Returns an immutable copy with selected fields replaced.
  ///
  /// Set [clearDefinition] or [clearSource] to remove those optional values.
  /// Supplying a value and its matching clear flag together is invalid.
  DashronymEntry copyWith({
    String? acronym,
    String? expansion,
    String? definition,
    bool clearDefinition = false,
    Iterable<String>? aliases,
    Iterable<String>? tags,
    String? source,
    bool clearSource = false,
    Map<String, Object?>? metadata,
  }) {
    if (clearDefinition && definition != null) {
      throw ArgumentError(
        'definition and clearDefinition cannot both be supplied',
      );
    }
    if (clearSource && source != null) {
      throw ArgumentError('source and clearSource cannot both be supplied');
    }

    return DashronymEntry(
      acronym: acronym ?? this.acronym,
      expansion: expansion ?? this.expansion,
      definition: clearDefinition ? null : definition ?? this.definition,
      aliases: aliases ?? this.aliases,
      tags: tags ?? this.tags,
      source: clearSource ? null : source ?? this.source,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DashronymEntry &&
      other.acronym == acronym &&
      other.expansion == expansion &&
      other.definition == definition &&
      jsonValueEquals(other.aliases, aliases) &&
      jsonValueEquals(other.tags, tags) &&
      other.source == source &&
      jsonValueEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
    acronym,
    expansion,
    definition,
    jsonValueHash(aliases),
    jsonValueHash(tags),
    source,
    jsonValueHash(metadata),
  );

  @override
  String toString() => 'DashronymEntry($acronym: $expansion)';
}

List<String> _decodeStringArray(JsonObjectReader reader, String key) {
  final values = reader.optionalList(key);
  return [
    for (var index = 0; index < values.length; index++)
      switch (values[index]) {
        final String value => value,
        final value => throw FormatException(
          '${reader.path}.$key[$index] must be a string; '
          'found ${value == null ? 'null' : value.runtimeType}',
        ),
      },
  ];
}

String _requiredText(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must not be empty');
  }
  if (value != value.trim()) {
    throw ArgumentError.value(
      value,
      name,
      'must not have leading or trailing whitespace',
    );
  }
  return value;
}

String? _optionalText(String? value, String name) =>
    value == null ? null : _requiredText(value, name);

List<String> _stringList(
  Iterable<String> values,
  String name, {
  String? disallowed,
}) {
  final result = <String>[];
  final seen = <String>{};
  for (final value in values) {
    final validated = _requiredText(value, name);
    if (validated == disallowed) {
      throw ArgumentError.value(
        value,
        name,
        'must not repeat the canonical acronym',
      );
    }
    if (!seen.add(validated)) {
      throw ArgumentError.value(value, name, 'must not contain duplicates');
    }
    result.add(validated);
  }
  return List<String>.unmodifiable(result);
}
