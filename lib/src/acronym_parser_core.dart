import 'acronym_tokens.dart';
import 'config.dart';
import 'lru_cache.dart';
import 'registry.dart';

/// Pure-Dart acronym parser that produces [DashronymToken]s.
///
/// This parser is responsible for locating acronyms based on [DashronymConfig]
/// and [AcronymRegistry]. It does not know about Flutter, widgets, or spans.
///
/// Results are memoized in a parser-local [Lru] cache keyed by the input text,
/// so repeated parsing of identical content avoids recomputation without
/// sharing registry-resolved tokens between parser instances.
class DashronymParserCore {
  /// Creates a core parser backed by [registry] and [config].
  DashronymParserCore({
    required this.registry,
    required this.config,
    int cacheCapacity = 256,
  }) : _cache = Lru<String, List<DashronymToken>>(capacity: cacheCapacity),
       _markerRegexes = _createMarkerRegexes(config);

  /// Dictionary of acronyms and their descriptions used for matching.
  final AcronymRegistry registry;

  /// Parsing options such as markers, minimum/maximum lengths, and bare acronym
  /// support.
  final DashronymConfig config;

  final Lru<String, List<DashronymToken>> _cache;
  final List<RegExp> _markerRegexes;

  static final RegExp _bareAcronym = RegExp(r'\b([A-Z]{2,})\b');

  /// Converts [input] into a sequence of [DashronymToken]s.
  ///
  /// * Respects marker pairs from [DashronymConfig.acceptMarkers].
  /// * When [DashronymConfig.enableBareAcronyms] is `true`, matches bare
  ///   `[A-Z]{2,}` tokens within [DashronymConfig.minLen]…[DashronymConfig.maxLen].
  /// * Only acronyms present in [registry] are turned into [AcronymToken]s;
  ///   other segments are merged into [TextToken]s.
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
      tokens.add(TextToken(text));
      buffer = StringBuffer();
    }

    while (i < input.length) {
      var matched = false;

      // Try marker-based matches first.
      for (final rx in _markerRegexes) {
        final m = rx.matchAsPrefix(input, i);
        if (m != null) {
          final ac = m.group(1)!;
          final description = registry.descriptionOf(ac);
          if (description != null) {
            flushBuffer();
            tokens.add(
              AcronymToken(acronym: ac, description: description),
            );
            i = m.end;
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
              AcronymToken(acronym: ac, description: description),
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

  static List<RegExp> _createMarkerRegexes(DashronymConfig config) {
    config.validate();

    return List<RegExp>.unmodifiable(
      config.acceptMarkers.map((pair) {
        final [left, right] = pair.runes
            .map(String.fromCharCode)
            .toList(growable: false);
        return RegExp(
          '${RegExp.escape(left)}'
          '([A-Za-z0-9]{${config.minLen},${config.maxLen}})'
          '${RegExp.escape(right)}',
        );
      }),
    );
  }
}
