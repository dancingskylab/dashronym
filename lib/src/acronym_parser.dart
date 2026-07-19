import 'package:flutter/material.dart';

import 'acronym_inline.dart';
import 'acronym_parser_core.dart';
import 'acronym_tokens.dart';
import 'config.dart';
import 'dashronym_theme.dart';
import 'registry.dart';

/// Maps [DashronymToken]s produced by [DashronymParserCore] into [InlineSpan]s
/// with embedded acronym tooltip widgets.
///
/// This adapter is responsible for presentation concerns only – it creates
/// [TextSpan]s for plain text and [WidgetSpan]s that wrap [AcronymInline] for
/// matched acronyms.
///
/// Example:
/// ```dart
/// final registry = AcronymRegistry({
///   'SDK': 'Software Development Kit',
///   'API': 'Application Programming Interface',
/// });
///
/// final spans = DashronymParser(
///   registry: registry,
///   config: const DashronymConfig(enableBareAcronyms: true),
///   theme: const DashronymTheme(),
///   baseStyle: const TextStyle(fontSize: 14),
/// ).parseToSpans('Install the (SDK) to access the API.');
///
/// final widget = Text.rich(TextSpan(children: spans));
/// ```
class DashronymParser {
  /// Creates a parser that converts matched acronyms into inline tooltip widgets.
  DashronymParser({
    required this.registry,
    required this.config,
    required this.theme,
    required this.baseStyle,
    this.tooltipBuilder,
  }) : _core = DashronymParserCore(registry: registry, config: config);

  /// Dictionary of acronyms and their descriptions used for matching.
  final AcronymRegistry registry;

  /// Parsing options such as marker pairs, minimum/maximum lengths,
  /// and whether to consider bare ALL-CAPS words.
  final DashronymConfig config;

  /// Visual and interaction parameters for produced [AcronymInline] widgets.
  final DashronymTheme theme;

  /// Base [TextStyle] applied to text runs and passed to inline widgets.
  final TextStyle? baseStyle;

  /// Optional builder for a custom tooltip widget.
  final DashronymTooltipBuilder? tooltipBuilder;

  final DashronymParserCore _core;

  /// Converts [input] into a sequence of [InlineSpan]s with glossary tooltips.
  ///
  /// * Delegates tokenization to [DashronymParserCore].
  /// * Renders [TextToken]s as [TextSpan]s.
  /// * Renders [AcronymToken]s as [WidgetSpan]s that host [AcronymInline].
  List<InlineSpan> parseToSpans(
    String input, {
    Locale? locale,
    bool? spellOut,
    String? semanticsIdentifier,
  }) {
    final tokens = _core.parse(input);
    final spans = <InlineSpan>[];
    var remainingSemanticsIdentifier = semanticsIdentifier;

    for (final token in tokens) {
      final tokenSemanticsIdentifier = remainingSemanticsIdentifier;
      remainingSemanticsIdentifier = null;
      spans.add(
        switch (token) {
          TextToken(:final text) => TextSpan(
            text: text,
            locale: locale,
            spellOut: spellOut,
            semanticsIdentifier: tokenSemanticsIdentifier,
          ),
          AcronymToken(:final acronym, :final description) => WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: AcronymInline(
              acronym: acronym,
              description: description,
              theme: theme,
              textStyle: baseStyle,
              tooltipBuilder: tooltipBuilder,
              // RichText scales WidgetSpan children at the render-object
              // boundary. Scaling this Text again would square the factor.
              textScaler: TextScaler.noScaling,
              entry: registry.entryOf(acronym),
              locale: locale,
              spellOut: spellOut,
              semanticsIdentifier: tokenSemanticsIdentifier,
            ),
          ),
        },
      );
    }

    return List<InlineSpan>.unmodifiable(spans);
  }
}
