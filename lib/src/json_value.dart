import 'dart:collection';

/// Creates a deeply immutable, deterministically ordered JSON object.
///
/// Values must be JSON-compatible: `null`, booleans, strings, integers, finite
/// doubles, lists, and maps with string keys. Cycles and all other values are
/// rejected with an [ArgumentError] that identifies their path.
Map<String, Object?> freezeJsonMap(
  Map<Object?, Object?> source, {
  String path = r'$',
}) => _freezeMap(source, path, HashSet<Object>.identity());

/// Compares two already JSON-compatible values deeply.
bool jsonValueEquals(Object? left, Object? right) {
  if (identical(left, right)) return true;

  return switch ((left, right)) {
    (final List<Object?> left, final List<Object?> right) =>
      left.length == right.length &&
          Iterable<int>.generate(
            left.length,
          ).every((index) => jsonValueEquals(left[index], right[index])),
    (
      final Map<String, Object?> left,
      final Map<String, Object?> right,
    ) =>
      left.length == right.length &&
          left.keys.every(
            (key) =>
                right.containsKey(key) &&
                jsonValueEquals(left[key], right[key]),
          ),
    _ => left == right,
  };
}

/// Computes a deep hash for an already JSON-compatible value.
int jsonValueHash(Object? value) => switch (value) {
  final List<Object?> list => Object.hashAll(list.map(jsonValueHash)),
  final Map<String, Object?> map => Object.hashAll(
    (map.keys.toList()..sort()).map(
      (key) => Object.hash(key, jsonValueHash(map[key])),
    ),
  ),
  _ => value.hashCode,
};

/// Strictly reads fields from a JSON object and reports failures with paths.
final class JsonObjectReader {
  JsonObjectReader._(this.values, this.path);

  /// Converts [value] into an object reader rooted at [path].
  factory JsonObjectReader.from(Object? value, {required String path}) {
    if (value case final Map<Object?, Object?> map) {
      final converted = <String, Object?>{};
      for (final MapEntry(:key, :value) in map.entries) {
        if (key is! String) {
          throw FormatException(
            '$path must contain only string keys; found ${key.runtimeType}',
          );
        }
        converted[key] = value;
      }
      return JsonObjectReader._(
        Map<String, Object?>.unmodifiable(converted),
        path,
      );
    }

    throw FormatException(
      '$path must be a JSON object; found ${_typeName(value)}',
    );
  }

  /// The copied object values.
  final Map<String, Object?> values;

  /// The JSON-style path to this object.
  final String path;

  /// Rejects keys not present in [allowed].
  void rejectUnknownKeys(Set<String> allowed) {
    final unknown = values.keys.where((key) => !allowed.contains(key)).toList()
      ..sort();
    if (unknown.isNotEmpty) {
      throw FormatException(
        '$path contains unsupported ${unknown.length == 1 ? 'field' : 'fields'}: '
        '${unknown.join(', ')}. Put extension data in metadata.',
      );
    }
  }

  /// Reads a required string.
  String requiredString(String key) {
    final value = _required(key);
    if (value case final String result) return result;
    throw _wrongType(key, 'a string', value);
  }

  /// Reads an optional string, rejecting an explicit JSON `null`.
  String? optionalString(String key) {
    if (!values.containsKey(key)) return null;
    final value = values[key];
    if (value case final String result) return result;
    throw _wrongType(key, 'a string', value);
  }

  /// Reads a required integer.
  int requiredInt(String key) {
    final value = _required(key);
    if (value case final int result) return result;
    throw _wrongType(key, 'an integer', value);
  }

  /// Reads a required list.
  List<Object?> requiredList(String key) {
    final value = _required(key);
    if (value case final List<Object?> result) {
      return List<Object?>.unmodifiable(result);
    }
    throw _wrongType(key, 'an array', value);
  }

  /// Reads an optional list, returning an empty list when absent.
  List<Object?> optionalList(String key) {
    if (!values.containsKey(key)) return const [];
    final value = values[key];
    if (value case final List<Object?> result) {
      return List<Object?>.unmodifiable(result);
    }
    throw _wrongType(key, 'an array', value);
  }

  /// Reads an optional JSON object, returning an empty object when absent.
  Map<String, Object?> optionalObject(String key) {
    if (!values.containsKey(key)) return const {};
    return JsonObjectReader.from(
      values[key],
      path: '$path.$key',
    ).values;
  }

  Object? _required(String key) {
    if (!values.containsKey(key)) {
      throw FormatException('$path.$key is required');
    }
    return values[key];
  }

  FormatException _wrongType(String key, String expected, Object? value) =>
      FormatException(
        '$path.$key must be $expected; found ${_typeName(value)}',
      );
}

Object? _freezeJsonValue(
  Object? value,
  String path,
  HashSet<Object> active,
) {
  return switch (value) {
    null || bool() || String() || int() => value,
    final double number when number.isFinite => number,
    double() => throw ArgumentError(
      '$path must be a finite JSON number',
    ),
    final List<Object?> list => _freezeList(list, path, active),
    final Map<Object?, Object?> map => _freezeMap(map, path, active),
    _ => throw ArgumentError(
      '$path contains non-JSON value of type ${value.runtimeType}',
    ),
  };
}

List<Object?> _freezeList(
  List<Object?> source,
  String path,
  HashSet<Object> active,
) {
  _enterContainer(source, path, active);
  try {
    return List<Object?>.unmodifiable([
      for (var index = 0; index < source.length; index++)
        _freezeJsonValue(source[index], '$path[$index]', active),
    ]);
  } finally {
    active.remove(source);
  }
}

Map<String, Object?> _freezeMap(
  Map<Object?, Object?> source,
  String path,
  HashSet<Object> active,
) {
  _enterContainer(source, path, active);
  try {
    final stringKeys = <String>[];
    for (final key in source.keys) {
      if (key is! String) {
        throw ArgumentError(
          '$path contains non-string key of type ${key.runtimeType}',
        );
      }
      stringKeys.add(key);
    }
    stringKeys.sort();

    return Map<String, Object?>.unmodifiable({
      for (final key in stringKeys)
        key: _freezeJsonValue(source[key], '$path.$key', active),
    });
  } finally {
    active.remove(source);
  }
}

void _enterContainer(Object container, String path, HashSet<Object> active) {
  if (!active.add(container)) {
    throw ArgumentError('$path contains a reference cycle');
  }
}

String _typeName(Object? value) =>
    value == null ? 'null' : value.runtimeType.toString();
