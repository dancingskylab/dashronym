part of 'dashronym_text.dart';

class _DashronymSpanTransformer {
  const _DashronymSpanTransformer({
    required this.registry,
    required this.config,
    required this.theme,
    required this.tooltipBuilder,
  });

  final DashronymRegistry registry;
  final DashronymConfig config;
  final DashronymTheme theme;
  final DashronymTooltipBuilder? tooltipBuilder;

  InlineSpan transform(
    InlineSpan span, {
    required TextStyle? inheritedStyle,
    required Locale? inheritedLocale,
    required bool inheritedSpellOut,
  }) {
    if (span is! TextSpan) {
      return span;
    }

    // An explicit label describes the author's intended spoken value. Parsing
    // inside that boundary could make its visual and semantic content diverge.
    if (span.semanticsLabel != null) {
      return span;
    }

    final effectiveStyle = _mergeTextStyle(inheritedStyle, span.style);
    final effectiveLocale = span.locale ?? inheritedLocale;
    final effectiveSpellOut = span.spellOut ?? inheritedSpellOut;
    final transformedChildren = span.children
        ?.map(
          (child) => transform(
            child,
            inheritedStyle: effectiveStyle,
            inheritedLocale: effectiveLocale,
            inheritedSpellOut: effectiveSpellOut,
          ),
        )
        .toList(growable: false);
    final sourceText = span.text;
    if (sourceText == null || sourceText.isEmpty) {
      return _copyTextSpan(span, children: transformedChildren);
    }

    final parsed =
        DashronymParser(
          registry: registry,
          config: config,
          theme: theme,
          baseStyle: effectiveStyle,
          tooltipBuilder: tooltipBuilder,
        ).parseToSpans(
          sourceText,
          locale: effectiveLocale,
          spellOut: effectiveSpellOut,
          semanticsIdentifier: span.semanticsIdentifier,
        );
    if (!parsed.any((part) => part is WidgetSpan)) {
      return _copyTextSpan(span, children: transformedChildren);
    }

    final transformedText = parsed.map((part) {
      if (part case final TextSpan textPart) {
        return TextSpan(
          text: textPart.text,
          recognizer: span.recognizer,
          mouseCursor: span.mouseCursor,
          onEnter: span.onEnter,
          onExit: span.onExit,
          semanticsIdentifier: textPart.semanticsIdentifier,
          locale: textPart.locale,
          spellOut: textPart.spellOut,
        );
      }
      return part;
    });

    return TextSpan(
      style: span.style,
      children: <InlineSpan>[
        ...transformedText,
        ...?transformedChildren,
      ],
      locale: span.locale,
      spellOut: span.spellOut,
    );
  }
}

TextStyle? _mergeTextStyle(TextStyle? inherited, TextStyle? own) {
  if (own == null) return inherited;
  if (inherited == null || !own.inherit) return own;
  return inherited.merge(own);
}

TextSpan _copyTextSpan(
  TextSpan span, {
  List<InlineSpan>? children,
  String? semanticsLabel,
}) {
  return TextSpan(
    text: span.text,
    children: children ?? span.children,
    style: span.style,
    recognizer: span.recognizer,
    mouseCursor: span.mouseCursor,
    onEnter: span.onEnter,
    onExit: span.onExit,
    semanticsLabel: semanticsLabel ?? span.semanticsLabel,
    semanticsIdentifier: span.semanticsIdentifier,
    locale: span.locale,
    spellOut: span.spellOut,
  );
}

InlineSpan _withoutPlainTextSemantics(InlineSpan span) {
  if (span case final TextSpan textSpan) {
    return _copyTextSpan(
      textSpan,
      children: textSpan.children
          ?.map(_withoutPlainTextSemantics)
          .toList(growable: false),
      semanticsLabel:
          textSpan.semanticsLabel ?? (textSpan.text == null ? null : ''),
    );
  }
  return span;
}
