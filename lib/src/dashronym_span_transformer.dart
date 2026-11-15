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
  TextStyle? style,
  String? semanticsLabel,
}) {
  return TextSpan(
    text: span.text,
    children: children ?? span.children,
    style: style ?? span.style,
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

const _leftToRightMark = TextSpan(text: '\u200E');
const _rightToLeftMark = TextSpan(text: '\u200F');

final _rightToLeftLetter = RegExp(
  r'[\p{Script=Hebrew}\p{Script=Arabic}\p{Script=Syriac}\p{Script=Thaana}'
  r'\p{Script=Nko}\p{Script=Samaritan}\p{Script=Mandaic}\p{Script=Adlam}]',
  unicode: true,
);
final _letter = RegExp(r'\p{L}', unicode: true);

/// The direction of the first letter in [text], or null if it has none.
TextDirection? _strongDirection(String text) {
  final letter = _letter.firstMatch(text)?[0];
  if (letter == null) return null;
  return _rightToLeftLetter.hasMatch(letter)
      ? TextDirection.rtl
      : TextDirection.ltr;
}

/// Brackets each acronym whose script runs against [paragraphDirection] with
/// matching directional marks.
///
/// Flutter lays out a [WidgetSpan] as U+FFFC, which the Unicode bidi
/// algorithm treats as neutral. In an Arabic paragraph that mentions
/// "SDK and API", the placeholders would take the paragraph's direction and
/// reverse the English run. The marks give each acronym the direction its
/// text has, so it lays out as the plain words would.
List<InlineSpan> _withDirectionalMarks(
  List<InlineSpan> spans,
  TextDirection paragraphDirection,
) {
  final marked = <InlineSpan>[];
  for (final span in spans) {
    if (span case WidgetSpan(child: DashronymInline(:final acronym))) {
      final direction = _strongDirection(acronym);
      if (direction != null && direction != paragraphDirection) {
        final mark = direction == TextDirection.ltr
            ? _leftToRightMark
            : _rightToLeftMark;
        marked.addAll([mark, span, mark]);
        continue;
      }
    } else if (span is TextSpan && span.runtimeType == TextSpan) {
      if (span.children case final children?) {
        marked.add(
          _copyTextSpan(
            span,
            children: _withDirectionalMarks(children, paragraphDirection),
          ),
        );
        continue;
      }
    }
    marked.add(span);
  }
  return marked;
}
