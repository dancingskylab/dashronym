import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Visual customization for inline acronym triggers and their tooltip cards.
///
/// Supply an instance to dashronym APIs (e.g., the inline acronym widget or
/// text extension) to control underline behavior, hover timing, tooltip
/// animation, card geometry, and iconography.
///
/// Example:
/// ```dart
/// const theme = DashronymTheme(
///   underline: true,
///   decorationStyle: TextDecorationStyle.dotted,
///   tooltipFadeDuration: Duration(milliseconds: 200),
///   cardWidth: 300,
///   cardBorderRadius: 10,
///   cardIcon: Icons.info_outline,
///   tooltipOffset: Offset(0, 8),
/// );
/// ```
class DashronymTheme extends ThemeExtension<DashronymTheme> {
  static const Object _sentinel = Object();

  /// Creates a theme describing trigger styling and tooltip card presentation.
  ///
  /// Asserts that [cardWidth] is positive and [cardElevation] is non-negative.
  const DashronymTheme({
    this.underline = true,
    this.decorationStyle = TextDecorationStyle.dotted,
    this.decorationThickness,
    this.acronymStyle,
    this.cardWidth = 320,
    this.cardElevation = 8,
    this.cardPadding = const EdgeInsets.all(8),
    this.hoverShowDelay = const Duration(milliseconds: 250),
    this.hoverHideDelay,
    this.tooltipFadeDuration = const Duration(milliseconds: 150),
    this.enableHover = true,
    this.cardBorderRadius = 12,
    this.cardIcon = Icons.info_outline,
    this.cardCloseIcon = Icons.close,
    this.cardIconColor,
    this.cardTitleStyle,
    this.cardSubtitleStyle,
    this.cardContentPadding = const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    this.cardMinLeadingWidth = 24,
    this.tooltipOffset = const Offset(0, 6),
    this.tooltipFadeInCurve = Curves.easeOut,
    this.tooltipFadeOutCurve = Curves.easeIn,
    this.tooltipScaleInCurve = Curves.easeOut,
    this.tooltipScaleOutCurve = Curves.easeIn,
    this.tooltipScaleBegin = 0.95,
    this.tooltipScaleEnd = 1.0,
    this.tooltipMinWidth,
    this.tooltipMaxWidth,
  }) : assert(cardWidth > 0, 'cardWidth must be positive.'),
       assert(cardElevation >= 0, 'cardElevation cannot be negative.'),
       assert(tooltipScaleBegin > 0, 'tooltipScaleBegin must be positive.'),
       assert(
         tooltipScaleEnd >= tooltipScaleBegin,
         'tooltipScaleEnd must be >= tooltipScaleBegin.',
       ),
       assert(
         tooltipMinWidth == null || tooltipMinWidth >= 0,
         'tooltipMinWidth cannot be negative.',
       ),
       assert(
         tooltipMaxWidth == null || tooltipMaxWidth > 0,
         'tooltipMaxWidth must be positive when provided.',
       ),
       assert(
         tooltipMinWidth == null ||
             tooltipMaxWidth == null ||
             tooltipMinWidth <= tooltipMaxWidth,
         'tooltipMinWidth must be <= tooltipMaxWidth.',
       );

  /// Whether matched acronyms are underlined in the inline trigger.
  final bool underline;

  /// The [TextDecorationStyle] used when [underline] is `true`.
  final TextDecorationStyle decorationStyle;

  /// The underline thickness; when `null`, the base text style decides.
  final double? decorationThickness;

  /// Style override for the inline acronym text (e.g., weight or color).
  final TextStyle? acronymStyle;

  /// Maximum width of the tooltip card in logical pixels.
  final double cardWidth;

  /// Material elevation of the tooltip card.
  final double cardElevation;

  /// Inner padding for the tooltip card's content area.
  final EdgeInsets cardPadding;

  /// Delay before showing the tooltip when the pointer hovers the trigger.
  final Duration hoverShowDelay;

  /// Delay before hiding after the pointer leaves the trigger.
  ///
  /// If `null`, defaults to [hoverShowDelay].
  final Duration? hoverHideDelay;

  /// Duration of the tooltip's fade in/out animation.
  final Duration tooltipFadeDuration;

  /// Enables hover-triggered behavior on desktop/web when `true`.
  final bool enableHover;

  /// Corner radius for the tooltip card's rounded rectangle.
  final double cardBorderRadius;

  /// Leading icon displayed inside the tooltip card.
  final IconData cardIcon;

  /// Trailing close icon used by the tooltip's dismiss button.
  final IconData cardCloseIcon;

  /// Color applied to icons inside the tooltip card; falls back to theme.
  final Color? cardIconColor;

  /// Text style for the acronym title in the card.
  final TextStyle? cardTitleStyle;

  /// Text style for the description subtitle in the card.
  final TextStyle? cardSubtitleStyle;

  /// Extra padding applied to the [ListTile] content within the card.
  final EdgeInsets cardContentPadding;

  /// Minimum width reserved for the card's leading widget.
  final double cardMinLeadingWidth;

  /// Offset of the tooltip relative to the inline trigger's origin.
  final Offset tooltipOffset;

  /// Curve used when fading the tooltip into view.
  final Curve tooltipFadeInCurve;

  /// Curve used when fading the tooltip out of view.
  final Curve tooltipFadeOutCurve;

  /// Curve used when scaling the tooltip into view.
  final Curve tooltipScaleInCurve;

  /// Curve used when scaling the tooltip out of view.
  final Curve tooltipScaleOutCurve;

  /// Starting scale factor applied to the tooltip during the show animation.
  final double tooltipScaleBegin;

  /// Ending scale factor applied to the tooltip during the show animation.
  final double tooltipScaleEnd;

  /// Minimum width constraint applied to the tooltip card.
  final double? tooltipMinWidth;

  /// Maximum width constraint applied to the tooltip card.
  ///
  /// Falls back to [cardWidth] when `null`.
  final double? tooltipMaxWidth;

  /// Creates a copy with the provided fields replaced.
  ///
  /// Use a `clear…` flag to remove its corresponding nullable value. Supplying
  /// both a replacement and its clear flag throws [ArgumentError].
  ///
  /// For compatibility with earlier releases, passing `null` explicitly to
  /// [hoverHideDelay] clears that value; omitting it retains the current value.
  @override
  DashronymTheme copyWith({
    bool? underline,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    bool clearDecorationThickness = false,
    TextStyle? acronymStyle,
    bool clearAcronymStyle = false,
    double? cardWidth,
    double? cardElevation,
    EdgeInsets? cardPadding,
    Duration? hoverShowDelay,
    Object? hoverHideDelay = _sentinel,
    Duration? tooltipFadeDuration,
    bool? enableHover,
    double? cardBorderRadius,
    IconData? cardIcon,
    IconData? cardCloseIcon,
    Color? cardIconColor,
    bool clearCardIconColor = false,
    TextStyle? cardTitleStyle,
    bool clearCardTitleStyle = false,
    TextStyle? cardSubtitleStyle,
    bool clearCardSubtitleStyle = false,
    EdgeInsets? cardContentPadding,
    double? cardMinLeadingWidth,
    Offset? tooltipOffset,
    Curve? tooltipFadeInCurve,
    Curve? tooltipFadeOutCurve,
    Curve? tooltipScaleInCurve,
    Curve? tooltipScaleOutCurve,
    double? tooltipScaleBegin,
    double? tooltipScaleEnd,
    double? tooltipMinWidth,
    bool clearTooltipMinWidth = false,
    double? tooltipMaxWidth,
    bool clearTooltipMaxWidth = false,
  }) {
    _rejectReplacementAndClear(
      decorationThickness,
      clearDecorationThickness,
      'decorationThickness',
      'clearDecorationThickness',
    );
    _rejectReplacementAndClear(
      acronymStyle,
      clearAcronymStyle,
      'acronymStyle',
      'clearAcronymStyle',
    );
    _rejectReplacementAndClear(
      cardIconColor,
      clearCardIconColor,
      'cardIconColor',
      'clearCardIconColor',
    );
    _rejectReplacementAndClear(
      cardTitleStyle,
      clearCardTitleStyle,
      'cardTitleStyle',
      'clearCardTitleStyle',
    );
    _rejectReplacementAndClear(
      cardSubtitleStyle,
      clearCardSubtitleStyle,
      'cardSubtitleStyle',
      'clearCardSubtitleStyle',
    );
    _rejectReplacementAndClear(
      tooltipMinWidth,
      clearTooltipMinWidth,
      'tooltipMinWidth',
      'clearTooltipMinWidth',
    );
    _rejectReplacementAndClear(
      tooltipMaxWidth,
      clearTooltipMaxWidth,
      'tooltipMaxWidth',
      'clearTooltipMaxWidth',
    );

    return DashronymTheme(
      underline: underline ?? this.underline,
      decorationStyle: decorationStyle ?? this.decorationStyle,
      decorationThickness: clearDecorationThickness
          ? null
          : decorationThickness ?? this.decorationThickness,
      acronymStyle: clearAcronymStyle
          ? null
          : acronymStyle ?? this.acronymStyle,
      cardWidth: cardWidth ?? this.cardWidth,
      cardElevation: cardElevation ?? this.cardElevation,
      cardPadding: cardPadding ?? this.cardPadding,
      hoverShowDelay: hoverShowDelay ?? this.hoverShowDelay,
      hoverHideDelay: identical(hoverHideDelay, _sentinel)
          ? this.hoverHideDelay
          : hoverHideDelay as Duration?,
      tooltipFadeDuration: tooltipFadeDuration ?? this.tooltipFadeDuration,
      enableHover: enableHover ?? this.enableHover,
      cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
      cardIcon: cardIcon ?? this.cardIcon,
      cardCloseIcon: cardCloseIcon ?? this.cardCloseIcon,
      cardIconColor: clearCardIconColor
          ? null
          : cardIconColor ?? this.cardIconColor,
      cardTitleStyle: clearCardTitleStyle
          ? null
          : cardTitleStyle ?? this.cardTitleStyle,
      cardSubtitleStyle: clearCardSubtitleStyle
          ? null
          : cardSubtitleStyle ?? this.cardSubtitleStyle,
      cardContentPadding: cardContentPadding ?? this.cardContentPadding,
      cardMinLeadingWidth: cardMinLeadingWidth ?? this.cardMinLeadingWidth,
      tooltipOffset: tooltipOffset ?? this.tooltipOffset,
      tooltipFadeInCurve: tooltipFadeInCurve ?? this.tooltipFadeInCurve,
      tooltipFadeOutCurve: tooltipFadeOutCurve ?? this.tooltipFadeOutCurve,
      tooltipScaleInCurve: tooltipScaleInCurve ?? this.tooltipScaleInCurve,
      tooltipScaleOutCurve: tooltipScaleOutCurve ?? this.tooltipScaleOutCurve,
      tooltipScaleBegin: tooltipScaleBegin ?? this.tooltipScaleBegin,
      tooltipScaleEnd: tooltipScaleEnd ?? this.tooltipScaleEnd,
      tooltipMinWidth: clearTooltipMinWidth
          ? null
          : tooltipMinWidth ?? this.tooltipMinWidth,
      tooltipMaxWidth: clearTooltipMaxWidth
          ? null
          : tooltipMaxWidth ?? this.tooltipMaxWidth,
    );
  }

  /// Returns a theme that falls back to the current values when [other] omits
  /// nullable values.
  DashronymTheme merge(DashronymTheme? other) {
    if (other == null) return this;
    return copyWith(
      underline: other.underline,
      decorationStyle: other.decorationStyle,
      decorationThickness: other.decorationThickness ?? decorationThickness,
      acronymStyle: other.acronymStyle ?? acronymStyle,
      cardWidth: other.cardWidth,
      cardElevation: other.cardElevation,
      cardPadding: other.cardPadding,
      hoverShowDelay: other.hoverShowDelay,
      hoverHideDelay: other.hoverHideDelay ?? hoverHideDelay,
      tooltipFadeDuration: other.tooltipFadeDuration,
      enableHover: other.enableHover,
      cardBorderRadius: other.cardBorderRadius,
      cardIcon: other.cardIcon,
      cardCloseIcon: other.cardCloseIcon,
      cardIconColor: other.cardIconColor ?? cardIconColor,
      cardTitleStyle: other.cardTitleStyle ?? cardTitleStyle,
      cardSubtitleStyle: other.cardSubtitleStyle ?? cardSubtitleStyle,
      cardContentPadding: other.cardContentPadding,
      cardMinLeadingWidth: other.cardMinLeadingWidth,
      tooltipOffset: other.tooltipOffset,
      tooltipFadeInCurve: other.tooltipFadeInCurve,
      tooltipFadeOutCurve: other.tooltipFadeOutCurve,
      tooltipScaleInCurve: other.tooltipScaleInCurve,
      tooltipScaleOutCurve: other.tooltipScaleOutCurve,
      tooltipScaleBegin: other.tooltipScaleBegin,
      tooltipScaleEnd: other.tooltipScaleEnd,
      tooltipMinWidth: other.tooltipMinWidth ?? tooltipMinWidth,
      tooltipMaxWidth: other.tooltipMaxWidth ?? tooltipMaxWidth,
    );
  }

  /// Interpolates between this theme and [other].
  ///
  /// This makes `DashronymTheme` suitable for
  /// `ThemeData.extensions` and animated app-theme transitions.
  @override
  DashronymTheme lerp(covariant DashronymTheme? other, double t) {
    if (other == null) return this;

    return DashronymTheme(
      underline: _select(underline, other.underline, t),
      decorationStyle: _select(
        decorationStyle,
        other.decorationStyle,
        t,
      ),
      decorationThickness: _lerpNullableDouble(
        decorationThickness,
        other.decorationThickness,
        t,
      ),
      acronymStyle: TextStyle.lerp(acronymStyle, other.acronymStyle, t),
      cardWidth: lerpDouble(cardWidth, other.cardWidth, t)!,
      cardElevation: lerpDouble(cardElevation, other.cardElevation, t)!,
      cardPadding: EdgeInsets.lerp(cardPadding, other.cardPadding, t)!,
      hoverShowDelay: _lerpDuration(
        hoverShowDelay,
        other.hoverShowDelay,
        t,
      ),
      hoverHideDelay: _lerpNullableDuration(
        hoverHideDelay,
        other.hoverHideDelay,
        t,
      ),
      tooltipFadeDuration: _lerpDuration(
        tooltipFadeDuration,
        other.tooltipFadeDuration,
        t,
      ),
      enableHover: _select(enableHover, other.enableHover, t),
      cardBorderRadius: lerpDouble(
        cardBorderRadius,
        other.cardBorderRadius,
        t,
      )!,
      cardIcon: _select(cardIcon, other.cardIcon, t),
      cardCloseIcon: _select(cardCloseIcon, other.cardCloseIcon, t),
      cardIconColor: Color.lerp(cardIconColor, other.cardIconColor, t),
      cardTitleStyle: TextStyle.lerp(
        cardTitleStyle,
        other.cardTitleStyle,
        t,
      ),
      cardSubtitleStyle: TextStyle.lerp(
        cardSubtitleStyle,
        other.cardSubtitleStyle,
        t,
      ),
      cardContentPadding: EdgeInsets.lerp(
        cardContentPadding,
        other.cardContentPadding,
        t,
      )!,
      cardMinLeadingWidth: lerpDouble(
        cardMinLeadingWidth,
        other.cardMinLeadingWidth,
        t,
      )!,
      tooltipOffset: Offset.lerp(tooltipOffset, other.tooltipOffset, t)!,
      tooltipFadeInCurve: _select(
        tooltipFadeInCurve,
        other.tooltipFadeInCurve,
        t,
      ),
      tooltipFadeOutCurve: _select(
        tooltipFadeOutCurve,
        other.tooltipFadeOutCurve,
        t,
      ),
      tooltipScaleInCurve: _select(
        tooltipScaleInCurve,
        other.tooltipScaleInCurve,
        t,
      ),
      tooltipScaleOutCurve: _select(
        tooltipScaleOutCurve,
        other.tooltipScaleOutCurve,
        t,
      ),
      tooltipScaleBegin: lerpDouble(
        tooltipScaleBegin,
        other.tooltipScaleBegin,
        t,
      )!,
      tooltipScaleEnd: lerpDouble(
        tooltipScaleEnd,
        other.tooltipScaleEnd,
        t,
      )!,
      tooltipMinWidth: _lerpNullableDouble(
        tooltipMinWidth,
        other.tooltipMinWidth,
        t,
      ),
      tooltipMaxWidth: _lerpNullableDouble(
        tooltipMaxWidth,
        other.tooltipMaxWidth,
        t,
      ),
    );
  }

  static T _select<T>(T begin, T end, double t) => t < 0.5 ? begin : end;

  static double? _lerpNullableDouble(double? begin, double? end, double t) {
    if (begin == null || end == null) return _select(begin, end, t);
    return lerpDouble(begin, end, t);
  }

  static Duration _lerpDuration(Duration begin, Duration end, double t) {
    return Duration(
      microseconds: lerpDouble(
        begin.inMicroseconds,
        end.inMicroseconds,
        t,
      )!.round(),
    );
  }

  static Duration? _lerpNullableDuration(
    Duration? begin,
    Duration? end,
    double t,
  ) {
    if (begin == null || end == null) return _select(begin, end, t);
    return _lerpDuration(begin, end, t);
  }

  static void _rejectReplacementAndClear(
    Object? replacement,
    bool clear,
    String replacementName,
    String clearName,
  ) {
    if (replacement != null && clear) {
      throw ArgumentError(
        '$replacementName and $clearName cannot both be supplied',
      );
    }
  }
}
