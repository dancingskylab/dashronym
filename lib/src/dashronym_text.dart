import 'package:flutter/material.dart';

import 'config.dart';
import 'acronym_parser.dart';
import 'acronym_inline.dart';
import 'dashronym_scope.dart';
import 'registry.dart';
import 'dashronym_theme.dart';

/// Renders text with inline, accessible glossary tooltips for matched acronyms.
///
/// This widget scans [text] using the provided [AcronymRegistry] and replaces
/// matches with interactive [WidgetSpan]s (see [AcronymInline]) while
/// preserving your typography, layout, and semantics. Non-matching text is
/// emitted as regular [TextSpan]s. The result is painted by a [RichText]
/// configured from the surrounding [DefaultTextStyle] and the provided
/// constructor parameters.
///
/// Example:
/// ```dart
/// final registry = AcronymRegistry({
///   'SDK': 'Software Development Kit',
///   'API': 'Application Programming Interface',
/// });
///
/// const theme = DashronymTheme(underline: true);
///
/// const text = 'Install the SDK to use the API.';
///
/// DashronymText(
///   text,
///   registry: registry,
///   theme: theme,
///   style: TextStyle(fontSize: 14),
/// )
/// ```
class DashronymText extends StatelessWidget {
  /// Creates a text widget that decorates matched acronyms with glossary tooltips.
  const DashronymText(
    this.text, {
    super.key,
    this.registry,
    this.config,
    this.theme,
    this.tooltipBuilder,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : inlineSpan = null;

  /// Creates a glossary-aware widget from an existing inline-span tree.
  ///
  /// Text inside nested [TextSpan]s is processed recursively while existing
  /// [WidgetSpan]s and span metadata are preserved. A span with an explicit
  /// [TextSpan.semanticsLabel] is treated as an author-controlled semantics
  /// boundary and is left unchanged.
  ///
  /// For compatibility, [text] remains a non-null [String] and is `''` for
  /// instances created by this constructor. The original tree is available
  /// through [inlineSpan].
  const DashronymText.rich(
    InlineSpan textSpan, {
    super.key,
    this.registry,
    this.config,
    this.theme,
    this.tooltipBuilder,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : text = '',
       inlineSpan = textSpan;

  /// The plain text to render and scan for acronyms.
  ///
  /// This is `''` for [DashronymText.rich]; use [inlineSpan] to inspect that
  /// constructor's source tree.
  final String text;

  /// The rich source tree, when created with [DashronymText.rich].
  final InlineSpan? inlineSpan;

  /// Acronym definitions used to resolve matches.
  ///
  /// When omitted, the nearest [DashronymScope] supplies the registry.
  final AcronymRegistry? registry;

  /// Parser options such as markers, min/max lengths, and bare acronym support.
  ///
  /// Resolution order is this value, [DashronymScope.config], then package
  /// defaults.
  final DashronymConfig? config;

  /// Visual customization for the inline trigger and the tooltip card.
  ///
  /// Resolution order is this value, [DashronymScope.theme], the
  /// [DashronymTheme] in [ThemeData.extensions], then package defaults.
  final DashronymTheme? theme;

  /// Optional builder for a custom tooltip widget.
  ///
  /// When provided, this is passed down to the underlying inline controls so
  /// you can replace the stock tooltip card while retaining Dashronym's
  /// trigger, overlay, dismissal, and viewport constraints. The builder owns
  /// its content semantics, labels, reading order, and controls.
  final DashronymTooltipBuilder? tooltipBuilder;

  /// Base text style for the output spans.
  ///
  /// If `null` or if [TextStyle.inherit] is `true`, this is merged with
  /// [DefaultTextStyle.of] to produce the effective style.
  final TextStyle? style;

  /// Strut configuration forwarded to the underlying [RichText].
  final StrutStyle? strutStyle;

  /// Horizontal alignment for the rendered text.
  final TextAlign? textAlign;

  /// Explicit text direction override (otherwise inherited).
  final TextDirection? textDirection;

  /// Locale used to select fonts.
  final Locale? locale;

  /// Whether the text should soft-wrap at line breaks.
  final bool? softWrap;

  /// Overflow behavior at the layout boundary.
  final TextOverflow? overflow;

  /// Modern text scaling configuration.
  final TextScaler? textScaler;

  /// Maximum number of lines to display.
  final int? maxLines;

  /// Optional semantics label read by accessibility services.
  ///
  /// When provided, this replaces the non-interactive prose exposed by the
  /// [RichText]. Matched acronyms remain separate semantic buttons, so adding
  /// a label does not make glossary definitions unreachable.
  final String? semanticsLabel;

  /// Optional stable identifier exposed on the outer semantics node.
  final String? semanticsIdentifier;

  /// Basis for computing text width.
  final TextWidthBasis? textWidthBasis;

  /// Text height behavior override.
  final TextHeightBehavior? textHeightBehavior;

  /// Selection highlight color.
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    final scope = DashronymScope.maybeOf(context);
    final effectiveRegistry = registry ?? scope?.registry;
    if (effectiveRegistry == null) {
      throw FlutterError.fromParts([
        ErrorSummary('DashronymText requires an AcronymRegistry.'),
        ErrorDescription(
          'No registry was passed to DashronymText and no DashronymScope '
          'was found above it.',
        ),
        ErrorHint(
          'Pass registry: AcronymRegistry({...}) or wrap this subtree in a '
          'DashronymScope.',
        ),
      ]);
    }
    final effectiveConfig = config ?? scope?.config ?? const DashronymConfig();
    final effectiveTheme =
        theme ??
        scope?.theme ??
        Theme.of(context).extension<DashronymTheme>() ??
        const DashronymTheme();
    final effectiveTooltipBuilder = tooltipBuilder ?? scope?.tooltipBuilder;

    final defaultTextStyle = DefaultTextStyle.of(context);
    final providedStyle = style;

    // Derive effective style by merging with the inherited default.
    TextStyle resolvedStyle;
    if (providedStyle == null || providedStyle.inherit) {
      resolvedStyle = defaultTextStyle.style.merge(providedStyle);
    } else {
      resolvedStyle = providedStyle;
    }
    if (MediaQuery.boldTextOf(context)) {
      resolvedStyle = resolvedStyle.merge(
        const TextStyle(fontWeight: FontWeight.bold),
      );
    }

    // Resolve layout defaults from the ambient DefaultTextStyle.
    final effectiveTextAlign =
        textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start;
    final effectiveSoftWrap = softWrap ?? defaultTextStyle.softWrap;
    final effectiveMaxLines = maxLines ?? defaultTextStyle.maxLines;
    final effectiveOverflow =
        overflow ?? resolvedStyle.overflow ?? defaultTextStyle.overflow;
    final effectiveTextWidthBasis =
        textWidthBasis ?? defaultTextStyle.textWidthBasis;
    final effectiveTextHeightBehavior =
        textHeightBehavior ??
        defaultTextStyle.textHeightBehavior ??
        DefaultTextHeightBehavior.maybeOf(context);
    final ambientMediaQuery = MediaQuery.maybeOf(context);
    final effectiveTextScaler =
        textScaler ?? ambientMediaQuery?.textScaler ?? TextScaler.noScaling;
    final effectiveTextDirection =
        textDirection ?? Directionality.maybeOf(context) ?? TextDirection.ltr;
    final effectiveLocale = locale ?? Localizations.maybeLocaleOf(context);
    final selectionRegistrar = SelectionContainer.maybeOf(context);
    final effectiveSelectionColor =
        selectionColor ??
        DefaultSelectionStyle.of(context).selectionColor ??
        DefaultSelectionStyle.defaultColor;

    // Parse the source into spans with inline tooltip widgets.
    final sourceSpan = inlineSpan;
    final spans = sourceSpan == null
        ? DashronymParser(
            registry: effectiveRegistry,
            config: effectiveConfig,
            theme: effectiveTheme,
            baseStyle: resolvedStyle,
            tooltipBuilder: effectiveTooltipBuilder,
          ).parseToSpans(text, locale: effectiveLocale)
        : <InlineSpan>[
            _DashronymSpanTransformer(
              registry: effectiveRegistry,
              config: effectiveConfig,
              theme: effectiveTheme,
              tooltipBuilder: effectiveTooltipBuilder,
            ).transform(
              sourceSpan,
              inheritedStyle: resolvedStyle,
              inheritedLocale: effectiveLocale,
              inheritedSpellOut: false,
            ),
          ];

    final textSpan = TextSpan(
      style: resolvedStyle,
      children: semanticsLabel == null
          ? spans
          : spans.map(_withoutPlainTextSemantics).toList(),
    );

    Widget result = RichText(
      textAlign: effectiveTextAlign,
      textDirection: effectiveTextDirection,
      locale: effectiveLocale,
      softWrap: effectiveSoftWrap,
      overflow: effectiveOverflow,
      textScaler: effectiveTextScaler,
      maxLines: effectiveMaxLines,
      strutStyle: strutStyle,
      textWidthBasis: effectiveTextWidthBasis,
      textHeightBehavior: effectiveTextHeightBehavior,
      selectionRegistrar: selectionRegistrar,
      selectionColor: effectiveSelectionColor,
      text: textSpan,
    );

    // Keep the original scaler ambient for tooltip content and direct child
    // widgets. Dashronym's WidgetSpan trigger explicitly opts out at its Text
    // leaf because Flutter scales inline widgets at the render boundary.
    final mediaQuery =
        ambientMediaQuery ?? MediaQueryData.fromView(View.of(context));
    result = MediaQuery(
      data: mediaQuery.copyWith(textScaler: effectiveTextScaler),
      child: Directionality(
        textDirection: effectiveTextDirection,
        child: result,
      ),
    );
    if (locale != null) {
      result = Localizations.override(
        context: context,
        locale: effectiveLocale,
        child: result,
      );
    }
    if (semanticsLabel != null || semanticsIdentifier != null) {
      result = Semantics(
        container: semanticsLabel != null,
        explicitChildNodes: semanticsLabel != null,
        label: semanticsLabel,
        identifier: semanticsIdentifier,
        textDirection: effectiveTextDirection,
        child: result,
      );
    }

    return result;
  }
}

class _DashronymSpanTransformer {
  const _DashronymSpanTransformer({
    required this.registry,
    required this.config,
    required this.theme,
    required this.tooltipBuilder,
  });

  final AcronymRegistry registry;
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
