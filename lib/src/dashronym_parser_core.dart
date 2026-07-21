import 'dashronym_token.dart';
import 'dashronym_config.dart';
import 'lru_cache.dart';
import 'dashronym_registry.dart';

/// Pure-Dart acronym parser that produces [DashronymToken]s.
///
/// This parser is responsible for locating acronyms based on [DashronymConfig]
/// and [DashronymRegistry]. It does not know about Flutter, widgets, or spans.
///
/// Results are memoized in a parser-local [LruCache] cache keyed by the input text,
/// so repeated parsing of identical content avoids recomputation without
/// sharing registry-resolved tokens between parser instances.
class DashronymParserCore {
  /// Creates a core parser backed by [registry] and [config].
  DashronymParserCore({
    required this.registry,
    required this.config,
    int cacheCapacity = 256,
  }) : _cache = LruCache<String, List<DashronymToken>>(capacity: cacheCapacity),
       _markerPairs = _createMarkerPairs(config);

  /// Dictionary of acronyms and their descriptions used for matching.
  final DashronymRegistry registry;

  /// Parsing options such as markers, minimum/maximum lengths, and bare acronym
  /// support.
  final DashronymConfig config;

  final LruCache<String, List<DashronymToken>> _cache;
  final List<_MarkerPair> _markerPairs;

  static final RegExp _bareAcronym = RegExp(r'\b([A-Z]{2,})\b');

  /// Converts [input] into a sequence of [DashronymToken]s.
  ///
  /// * Respects marker pairs from [DashronymConfig.acceptMarkers].
  /// * When [DashronymConfig.enableBareAcronyms] is `true`, matches bare
  ///   `[A-Z]{2,}` tokens within [DashronymConfig.minLen]…[DashronymConfig.maxLen].
  /// * Only acronyms present in [registry] are turned into [DashronymMatchToken]s;
  ///   other segments are merged into [DashronymTextToken]s.
  /// * Returns cached results when this parser previously parsed [input].
  List<DashronymToken> parse(String input) {
    final cached = _cache.get(input);
    if (cached != null) return cached;

    final tokens = <DashronymToken>[];
    var buffer = StringBuffer();
    var i = 0;

    void flushBuffer() {
      final text = buffer.toString();
      if (text.isEmpty) return;
      tokens.add(DashronymTextToken(text));
      buffer = StringBuffer();
    }

    while (i < input.length) {
      var matched = false;

      // Try marker-based matches first.
      for (final marker in _markerPairs) {
        final markerMatch = marker.matchAsPrefix(
          input,
          i,
          minLength: config.minLen,
          maxLength: config.maxLen,
        );
        if (markerMatch != null) {
          final ac = markerMatch.acronym;
          final description = registry.descriptionOf(ac);
          if (description != null) {
            flushBuffer();
            tokens.add(
              DashronymMatchToken(acronym: ac, description: description),
            );
            i = markerMatch.end;
            matched = true;
            break;
          }
        }
      }
      if (matched) continue;

      // Optionally match bare ALL-CAPS tokens.
      if (config.enableBareAcronyms) {
        final m = _bareAcronym.matchAsPrefix(input, i);
        if (m != null) {
          final ac = m.group(1)!;
          final description = registry.descriptionOf(ac);
          if (ac.length >= config.minLen &&
              ac.length <= config.maxLen &&
              description != null) {
            flushBuffer();
            tokens.add(
              DashronymMatchToken(acronym: ac, description: description),
            );
            i = m.end;
            continue;
          }
        }
      }

      // No match; emit the current character as plain text.
      buffer.writeCharCode(input.codeUnitAt(i));
      i += 1;
    }

    flushBuffer();

    final result = List<DashronymToken>.unmodifiable(tokens);
    _cache.put(input, result);
    return result;
  }

  static List<_MarkerPair> _createMarkerPairs(DashronymConfig config) {
    config.validate();

    return List<_MarkerPair>.unmodifiable(
      config.acceptMarkers.map((pair) {
        final [left, right] = pair.runes
            .map(String.fromCharCode)
            .toList(growable: false);
        return _MarkerPair(
          left: left,
          right: right,
          rightScalar: right.runes.single,
        );
      }),
    );
  }
}

final class _MarkerPair {
  const _MarkerPair({
    required this.left,
    required this.right,
    required this.rightScalar,
  });

  final String left;
  final String right;
  final int rightScalar;

  _MarkerMatch? matchAsPrefix(
    String input,
    int start, {
    required int minLength,
    required int maxLength,
  }) {
    if (!input.startsWith(left, start)) return null;

    final contentStart = start + left.length;
    // Always use the first closing delimiter. An invalid or unknown candidate
    // must not consume a later closer to manufacture a different match.
    final iterator = RuneIterator.at(input, contentStart);
    var scalarLength = 0;
    while (iterator.moveNext()) {
      final scalar = iterator.current;
      if (scalar == rightScalar) {
        if (scalarLength < minLength) return null;
        return _MarkerMatch(
          acronym: input.substring(contentStart, iterator.rawIndex),
          end: iterator.rawIndex + right.length,
        );
      }
      if (_isLineBreak(scalar)) return null;
      scalarLength++;
      if (scalarLength > maxLength) return null;
    }

    return null;
  }

  static bool _isLineBreak(int scalar) =>
      scalar == 0x0A || scalar == 0x0D || scalar == 0x2028 || scalar == 0x2029;
}

final class _MarkerMatch {
  const _MarkerMatch({required this.acronym, required this.end});

  final String acronym;
  final int end;
}
