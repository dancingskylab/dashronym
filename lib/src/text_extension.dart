import 'package:flutter/material.dart';

import 'config.dart';
import 'dashronym_text.dart';
import 'dashronym_scope.dart';
import 'registry.dart';
import 'dashronym_theme.dart';
import 'acronym_inline.dart';

/// Convenience APIs for turning a plain [Text] into a glossary-aware widget.
///
/// Use this extension when you already have a [Text] widget and want to add
/// inline glossary tooltips without restructuring your tree. For new widgets,
/// you can also use [DashronymText] directly.
extension DashronymsTextX on Text {
  /// Returns a [DashronymText] that decorates matches with glossary tooltips.
  ///
  /// Plain text and nested `Text.rich` span trees are both processed. Existing
  /// [WidgetSpan]s are preserved, and a [TextSpan] with an explicit
  /// [TextSpan.semanticsLabel] is left unchanged as an author-controlled
  /// semantics boundary.
  ///
  /// [registry], [config], [theme], and [tooltipBuilder] may be inherited from
  /// [DashronymScope]. Explicit values take precedence.
  Widget dashronyms({
    AcronymRegistry? registry,
    DashronymConfig? config,
    DashronymTheme? theme,
    DashronymTooltipBuilder? tooltipBuilder,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap,
    TextOverflow? overflow,
    int? maxLines,
    String? semanticsLabel,
    String? semanticsIdentifier,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
    TextScaler? textScaler,
    Color? selectionColor,
  }) {
    if (data == null) {
      return DashronymText.rich(
        textSpan!,
        key: key,
        registry: registry,
        config: config,
        theme: theme,
        tooltipBuilder: tooltipBuilder,
        style: style ?? this.style,
        strutStyle: strutStyle ?? this.strutStyle,
        textAlign: textAlign ?? this.textAlign,
        textDirection: textDirection ?? this.textDirection,
        locale: locale ?? this.locale,
        softWrap: softWrap ?? this.softWrap,
        overflow: overflow ?? this.overflow,
        textScaler: textScaler ?? this.textScaler,
        maxLines: maxLines ?? this.maxLines,
        semanticsLabel: semanticsLabel ?? this.semanticsLabel,
        semanticsIdentifier: semanticsIdentifier ?? this.semanticsIdentifier,
        textWidthBasis: textWidthBasis ?? this.textWidthBasis,
        textHeightBehavior: textHeightBehavior ?? this.textHeightBehavior,
        selectionColor: selectionColor ?? this.selectionColor,
      );
    }

    return DashronymText(
      data!,
      key: key,
      registry: registry,
      config: config,
      theme: theme,
      tooltipBuilder: tooltipBuilder,
      style: style ?? this.style,
      strutStyle: strutStyle ?? this.strutStyle,
      textAlign: textAlign ?? this.textAlign,
      textDirection: textDirection ?? this.textDirection,
      locale: locale ?? this.locale,
      softWrap: softWrap ?? this.softWrap,
      overflow: overflow ?? this.overflow,
      textScaler: textScaler ?? this.textScaler,
      maxLines: maxLines ?? this.maxLines,
      semanticsLabel: semanticsLabel ?? this.semanticsLabel,
      semanticsIdentifier: semanticsIdentifier ?? this.semanticsIdentifier,
      textWidthBasis: textWidthBasis ?? this.textWidthBasis,
      textHeightBehavior: textHeightBehavior ?? this.textHeightBehavior,
      selectionColor: selectionColor ?? this.selectionColor,
    );
  }
}
