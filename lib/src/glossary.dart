import 'dart:convert';

import 'acronym_entry.dart';
import 'json_value.dart';
import 'registry.dart';

/// An immutable, versioned Dashronym glossary interchange document.
final class DashronymGlossary {
  /// The format identifier accepted by this package.
  static const String supportedFormat = 'dashronym.glossary';

  /// The schema version accepted by this package.
  static const int supportedSchemaVersion = 1;

  /// Creates a validated version-1 glossary.
  factory DashronymGlossary({
    required String name,
    Iterable<AcronymEntry> entries = const [],
    String? id,
    String? version,
    String? locale,
    String? license,
    String? source,
    DateTime? updatedAt,
    Map<String, Object?> metadata = const {},
  }) => DashronymGlossary._(
    name: _requiredText(name, 'name'),
    entries: List<AcronymEntry>.unmodifiable(entries),
    id: _optionalText(id, 'id'),
    version: _optionalText(version, 'version'),
    locale: _optionalText(locale, 'locale'),
    license: _optionalText(license, 'license'),
    source: _optionalText(source, 'source'),
    updatedAt: _normalizeUpdatedAt(updatedAt),
    metadata: freezeJsonMap(metadata, path: r'$.metadata'),
  );

  const DashronymGlossary._({
    required this.name,
    required this.entries,
    required this.id,
    required this.version,
    required this.locale,
    required this.license,
    required this.source,
    required this.updatedAt,
    required this.metadata,
  });

  /// Decodes a strict version-1 glossary JSON object.
  factory DashronymGlossary.fromJson(Object? json) {
    final reader = JsonObjectReader.from(json, path: r'$')
      ..rejectUnknownKeys(const {
        'format',
        'schemaVersion',
        'name',
        'id',
        'version',
        'locale',
        'license',
        'source',
        'updatedAt',
        'metadata',
        'entries',
      });

    final format = reader.requiredString('format');
    if (format != supportedFormat) {
      throw FormatException(
        r'$.format must be "'
        '$supportedFormat"; found "$format"',
      );
    }

    final schemaVersion = reader.requiredInt('schemaVersion');
    if (schemaVersion != supportedSchemaVersion) {
      throw FormatException(
        r'$.schemaVersion '
        'must be $supportedSchemaVersion; found $schemaVersion',
      );
    }

    final encodedEntries = reader.requiredList('entries');
    final entries = <AcronymEntry>[
      for (var index = 0; index < encodedEntries.length; index++)
        AcronymEntry.fromJson(
          encodedEntries[index],
          path:
              r'$.entries['
              '$index]',
        ),
    ];
    final encodedUpdatedAt = reader.optionalString('updatedAt');

    try {
      return DashronymGlossary(
        name: reader.requiredString('name'),
        entries: entries,
        id: reader.optionalString('id'),
        version: reader.optionalString('version'),
        locale: reader.optionalString('locale'),
        license: reader.optionalString('license'),
        source: reader.optionalString('source'),
        updatedAt: encodedUpdatedAt == null
            ? null
            : _parseUpdatedAt(encodedUpdatedAt),
        metadata: reader.optionalObject('metadata'),
      );
    } on ArgumentError catch (error) {
      throw FormatException(
        r'$ is invalid: '
        '${error.message}',
      );
    }
  }

  /// Decodes a glossary from a JSON string.
  factory DashronymGlossary.fromJsonString(String encoded) {
    try {
      return DashronymGlossary.fromJson(jsonDecode(encoded));
    } on FormatException catch (error) {
      throw FormatException('Invalid Dashronym glossary: ${error.message}');
    }
  }

  /// The invariant document format identifier.
  String get format => supportedFormat;

  /// The invariant document schema version.
  int get schemaVersion => supportedSchemaVersion;

  /// The human-readable glossary name.
  final String name;

  /// The glossary's canonical entries, in document order.
  final List<AcronymEntry> entries;

  /// An optional stable glossary identifier.
  final String? id;

  /// An optional publisher-defined content version.
  final String? version;

  /// An optional BCP 47 locale applying to the document.
  final String? locale;

  /// An optional SPDX expression, license URL, or license identifier.
  final String? license;

  /// An optional source URL, citation, or source identifier.
  final String? source;

  /// An optional UTC content update instant.
  final DateTime? updatedAt;

  /// Deeply immutable application-specific JSON data.
  final Map<String, Object?> metadata;

  /// Converts this glossary into a deterministic JSON-compatible object.
  Map<String, Object?> toJson() => {
    'format': format,
    'schemaVersion': schemaVersion,
    'name': name,
    if (id case final String id) 'id': id,
    if (version case final String version) 'version': version,
    if (locale case final String locale) 'locale': locale,
    if (license case final String license) 'license': license,
    if (source case final String source) 'source': source,
    if (updatedAt case final DateTime updatedAt)
      'updatedAt': updatedAt.toIso8601String(),
    'metadata': metadata,
    'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
  };

  /// Encodes this glossary as compact or two-space-indented JSON.
  String toJsonString({bool pretty = false}) => pretty
      ? const JsonEncoder.withIndent('  ').convert(toJson())
      : jsonEncode(toJson());

  /// Creates an immutable registry from this glossary's entries.
  AcronymRegistry toRegistry({
    bool caseInsensitive = true,
    AcronymDuplicatePolicy duplicatePolicy = AcronymDuplicatePolicy.reject,
  }) => AcronymRegistry.fromAcronymEntries(
    entries,
    caseInsensitive: caseInsensitive,
    duplicatePolicy: duplicatePolicy,
  );

  /// Returns an immutable copy with selected fields replaced.
  ///
  /// Each `clear…` flag removes its corresponding optional field. Supplying a
  /// replacement and its clear flag together is invalid.
  DashronymGlossary copyWith({
    String? name,
    Iterable<AcronymEntry>? entries,
    String? id,
    bool clearId = false,
    String? version,
    bool clearVersion = false,
    String? locale,
    bool clearLocale = false,
    String? license,
    bool clearLicense = false,
    String? source,
    bool clearSource = false,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
    Map<String, Object?>? metadata,
  }) {
    _rejectReplacementAndClear(id, clearId, 'id', 'clearId');
    _rejectReplacementAndClear(
      version,
      clearVersion,
      'version',
      'clearVersion',
    );
    _rejectReplacementAndClear(locale, clearLocale, 'locale', 'clearLocale');
    _rejectReplacementAndClear(
      license,
      clearLicense,
      'license',
      'clearLicense',
    );
    _rejectReplacementAndClear(source, clearSource, 'source', 'clearSource');
    _rejectReplacementAndClear(
      updatedAt,
      clearUpdatedAt,
      'updatedAt',
      'clearUpdatedAt',
    );

    return DashronymGlossary(
      name: name ?? this.name,
      entries: entries ?? this.entries,
      id: clearId ? null : id ?? this.id,
      version: clearVersion ? null : version ?? this.version,
      locale: clearLocale ? null : locale ?? this.locale,
      license: clearLicense ? null : license ?? this.license,
      source: clearSource ? null : source ?? this.source,
      updatedAt: clearUpdatedAt ? null : updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DashronymGlossary &&
      other.name == name &&
      jsonValueEquals(other.entries, entries) &&
      other.id == id &&
      other.version == version &&
      other.locale == locale &&
      other.license == license &&
      other.source == source &&
      other.updatedAt == updatedAt &&
      jsonValueEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
    name,
    jsonValueHash(entries),
    id,
    version,
    locale,
    license,
    source,
    updatedAt,
    jsonValueHash(metadata),
  );

  @override
  String toString() => 'DashronymGlossary($name, ${entries.length} entries)';
}

final RegExp _rfc3339DateTimePattern = RegExp(
  r'^([0-9]{4})-([0-9]{2})-([0-9]{2})'
  r'[Tt]([0-9]{2}):([0-9]{2}):([0-9]{2})'
  r'(?:\.([0-9]+))?'
  r'([Zz]|([+-])([0-9]{2}):([0-9]{2}))$',
);

DateTime _parseUpdatedAt(String value) {
  final match = _rfc3339DateTimePattern.firstMatch(value);
  if (match == null || match.end != value.length) {
    throw FormatException(
      r'$.updatedAt must use strict RFC 3339 date-time syntax '
      'with an explicit timezone',
    );
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final second = int.parse(match.group(6)!);

  if (month < 1 ||
      month > 12 ||
      day < 1 ||
      day > _daysInMonth(year, month) ||
      hour > 23 ||
      minute > 59 ||
      second > 60) {
    throw FormatException(
      r'$.updatedAt has an invalid RFC 3339 date or time component',
    );
  }

  var offsetMinutes = 0;
  if (match.group(8)!.toUpperCase() != 'Z') {
    final offsetHour = int.parse(match.group(10)!);
    final offsetMinute = int.parse(match.group(11)!);
    if (offsetHour > 23 || offsetMinute > 59) {
      throw FormatException(
        r'$.updatedAt has an invalid RFC 3339 timezone offset',
      );
    }
    offsetMinutes = offsetHour * 60 + offsetMinute;
    if (match.group(9) == '-') {
      offsetMinutes = -offsetMinutes;
    }
  }

  final fraction = (match.group(7) ?? '').padRight(6, '0');
  final microseconds = int.parse(fraction.substring(0, 6));
  var parsed = DateTime.utc(
    year,
    month,
    day,
    hour,
    minute,
    second == 60 ? 59 : second,
    microseconds ~/ Duration.microsecondsPerMillisecond,
    microseconds % Duration.microsecondsPerMillisecond,
  ).subtract(Duration(minutes: offsetMinutes));
  if (second == 60) {
    if (!_isPossibleLeapSecond(parsed)) {
      throw FormatException(
        r'$.updatedAt places an RFC 3339 leap second outside the end of '
        'June or December',
      );
    }
    parsed = parsed.add(const Duration(seconds: 1));
  }

  return parsed;
}

DateTime? _normalizeUpdatedAt(DateTime? value) {
  if (value == null) {
    return null;
  }

  final utc = value.toUtc();
  if (utc.year < 0 || utc.year > 9999) {
    throw ArgumentError.value(
      value,
      'updatedAt',
      'its UTC representation must have a four-digit year from 0000 '
          'through 9999',
    );
  }
  return utc;
}

int _daysInMonth(int year, int month) => switch (month) {
  2 when _isLeapYear(year) => 29,
  2 => 28,
  4 || 6 || 9 || 11 => 30,
  _ => 31,
};

bool _isLeapYear(int year) =>
    year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

bool _isPossibleLeapSecond(DateTime utc) =>
    utc.hour == 23 &&
    utc.minute == 59 &&
    utc.second == 59 &&
    ((utc.month == DateTime.june && utc.day == 30) ||
        (utc.month == DateTime.december && utc.day == 31));

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

void _rejectReplacementAndClear(
  Object? replacement,
  bool clear,
  String replacementName,
  String clearName,
) {
  if (clear && replacement != null) {
    throw ArgumentError(
      '$replacementName and $clearName cannot both be supplied',
    );
  }
}
