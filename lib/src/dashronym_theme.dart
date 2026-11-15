import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

/// Visual customization for inline acronym triggers and their tooltip cards.
///
/// Supply an instance to a Dashronym widget, a `DashronymScope`, or a
/// `DashronymThemeScope` to control underline behavior, hover timing, tooltip
/// animation, card geometry, colors, and iconography.
///
/// Every color and icon is optional. Unset values are derived from the host
/// app through the widgets layer, so the same theme works in Material,
/// Cupertino, and custom design-system apps.
///
/// Example:
/// ```dart
/// const theme = DashronymTheme(
///   underline: true,
///   decorationStyle: TextDecorationStyle.dotted,
///   tooltipFadeDuration: Duration(milliseconds: 200),
///   cardWidth: 300,
///   cardBorderRadius: 10,
///   cardColor: Color(0xFFFFFBFE),
///   tooltipOffset: Offset(0, 8),
/// );
/// ```
@immutable
class const DashronymTheme({
  /// Whether matched acronyms are underlined in the inline trigger.
  final bool underline = true,

  /// The [TextDecorationStyle] used when [underline] is `true`.
  final TextDecorationStyle decorationStyle = TextDecorationStyle.dotted,

  /// The underline thickness; when `null`, the base text style decides.
  final double? decorationThickness,

  /// Style override for the inline acronym text (e.g., weight or color).
  final TextStyle? acronymStyle,

  /// Background highlight painted behind a keyboard-focused acronym.
  ///
  /// When `null`, the trigger's text color at 12% opacity is used, or 24%
  /// when the platform requests high contrast.
  final Color? acronymFocusColor,

  /// Maximum width of the tooltip card in logical pixels.
  final double cardWidth = 320,

  /// Shadow elevation of the tooltip card surface.
  final double cardElevation = 8,

  /// Background color of the tooltip card.
  ///
  /// When `null`, a light or dark neutral surface is chosen to contrast with
  /// the ambient text color, falling back to the platform brightness.
  final Color? cardColor,

  /// Color of the card's elevation shadow; black when `null`.
  final Color? cardShadowColor,

  /// Outline drawn around the tooltip card.
  ///
  /// When `null`, the card has no outline unless the platform requests high
  /// contrast, in which case a 1 px outline in the card's text color is drawn.
  final BorderSide? cardBorderSide,

  /// Inner padding for the tooltip card's content area.
  final EdgeInsets cardPadding = const EdgeInsets.all(8),

  /// Delay before showing the tooltip when the pointer hovers the trigger.
  final Duration hoverShowDelay = const Duration(milliseconds: 250),

  /// Delay before hiding after the pointer leaves the trigger.
  ///
  /// If `null`, defaults to [hoverShowDelay].
  final Duration? hoverHideDelay,

  /// Duration of the tooltip's fade in/out animation.
  final Duration tooltipFadeDuration = const Duration(milliseconds: 150),

  /// Enables hover-triggered behavior on desktop/web when `true`.
  final bool enableHover = true,

  /// Corner radius for the tooltip card's rounded rectangle.
  final double cardBorderRadius = 12,

  /// Leading icon displayed inside the tooltip card.
  ///
  /// When `null`, a built-in information glyph is painted, which needs no
  /// icon font. Supply an icon from your design system to replace it, such as
  /// `Icons.info_outline` or `CupertinoIcons.info`.
  final IconData? cardIcon,

  /// Icon used by the tooltip card's close button.
  ///
  /// When `null`, a built-in close glyph is painted, which needs no icon font.
  final IconData? cardCloseIcon,

  /// Color applied to icons inside the tooltip card.
  ///
  /// When `null`, the ambient [IconTheme] color is used if it contrasts with
  /// the card surface, otherwise the card's text color.
  final Color? cardIconColor,

  /// Text style for the acronym title in the card.
  ///
  /// Merged over a bold version of the ambient [DefaultTextStyle].
  final TextStyle? cardTitleStyle,

  /// Text style for the description subtitle in the card.
  ///
  /// Merged over the ambient [DefaultTextStyle].
  final TextStyle? cardSubtitleStyle,

  /// Extra padding applied around the card's content row.
  final EdgeInsets cardContentPadding = const EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  ),

  /// Minimum width reserved for the card's leading widget.
  final double cardMinLeadingWidth = 24,

  /// Offset of the tooltip relative to the inline trigger's origin.
  final Offset tooltipOffset = const Offset(0, 6),

  /// Curve used when fading the tooltip into view.
  final Curve tooltipFadeInCurve = Curves.easeOut,

  /// Curve used when fading the tooltip out of view.
  final Curve tooltipFadeOutCurve = Curves.easeIn,

  /// Curve used when scaling the tooltip into view.
  final Curve tooltipScaleInCurve = Curves.easeOut,

  /// Curve used when scaling the tooltip out of view.
  final Curve tooltipScaleOutCurve = Curves.easeIn,

  /// Starting scale factor applied to the tooltip during the show animation.
  final double tooltipScaleBegin = 0.95,

  /// Ending scale factor applied to the tooltip during the show animation.
  final double tooltipScaleEnd = 1.0,

  /// Minimum width constraint applied to the tooltip card.
  final double? tooltipMinWidth,

  /// Maximum width constraint applied to the tooltip card.
  ///
  /// Falls back to [cardWidth] when `null`.
  final double? tooltipMaxWidth,
}) {
  static const Object _sentinel = Object();

  /// Creates a theme describing trigger styling and tooltip card presentation.
  ///
  /// Asserts that [cardWidth] is positive and [cardElevation] is non-negative.
  this
    : assert(cardWidth > 0, 'cardWidth must be positive.'),
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

  /// Creates a copy with the provided fields replaced.
  ///
  /// Use a `clear…` flag to remove its corresponding nullable value. Supplying
  /// both a replacement and its clear flag throws [ArgumentError].
  ///
  /// For compatibility with earlier releases, passing `null` explicitly to
  /// [hoverHideDelay] clears that value; omitting it retains the current value.
  DashronymTheme copyWith({
    bool? underline,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    bool clearDecorationThickness = false,
    TextStyle? acronymStyle,
    bool clearAcronymStyle = false,
    Color? acronymFocusColor,
    bool clearAcronymFocusColor = false,
    double? cardWidth,
    double? cardElevation,
    Color? cardColor,
    bool clearCardColor = false,
    Color? cardShadowColor,
    bool clearCardShadowColor = false,
    BorderSide? cardBorderSide,
    bool clearCardBorderSide = false,
    EdgeInsets? cardPadding,
    Duration? hoverShowDelay,
    Object? hoverHideDelay = _sentinel,
    Duration? tooltipFadeDuration,
    bool? enableHover,
    double? cardBorderRadius,
    IconData? cardIcon,
    bool clearCardIcon = false,
    IconData? cardCloseIcon,
    bool clearCardCloseIcon = false,
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
      acronymFocusColor,
      clearAcronymFocusColor,
      'acronymFocusColor',
      'clearAcronymFocusColor',
    );
    _rejectReplacementAndClear(
      cardColor,
      clearCardColor,
      'cardColor',
      'clearCardColor',
    );
    _rejectReplacementAndClear(
      cardShadowColor,
      clearCardShadowColor,
      'cardShadowColor',
      'clearCardShadowColor',
    );
    _rejectReplacementAndClear(
      cardBorderSide,
      clearCardBorderSide,
      'cardBorderSide',
      'clearCardBorderSide',
    );
    _rejectReplacementAndClear(
      cardIcon,
      clearCardIcon,
      'cardIcon',
      'clearCardIcon',
    );
    _rejectReplacementAndClear(
      cardCloseIcon,
      clearCardCloseIcon,
      'cardCloseIcon',
      'clearCardCloseIcon',
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
      acronymFocusColor: clearAcronymFocusColor
          ? null
          : acronymFocusColor ?? this.acronymFocusColor,
      cardWidth: cardWidth ?? this.cardWidth,
      cardElevation: cardElevation ?? this.cardElevation,
      cardColor: clearCardColor ? null : cardColor ?? this.cardColor,
      cardShadowColor: clearCardShadowColor
          ? null
          : cardShadowColor ?? this.cardShadowColor,
      cardBorderSide: clearCardBorderSide
          ? null
          : cardBorderSide ?? this.cardBorderSide,
      cardPadding: cardPadding ?? this.cardPadding,
      hoverShowDelay: hoverShowDelay ?? this.hoverShowDelay,
      hoverHideDelay: identical(hoverHideDelay, _sentinel)
          ? this.hoverHideDelay
          : hoverHideDelay as Duration?,
      tooltipFadeDuration: tooltipFadeDuration ?? this.tooltipFadeDuration,
      enableHover: enableHover ?? this.enableHover,
      cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
      cardIcon: clearCardIcon ? null : cardIcon ?? this.cardIcon,
      cardCloseIcon: clearCardCloseIcon
          ? null
          : cardCloseIcon ?? this.cardCloseIcon,
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
      acronymFocusColor: other.acronymFocusColor ?? acronymFocusColor,
      cardWidth: other.cardWidth,
      cardElevation: other.cardElevation,
      cardColor: other.cardColor ?? cardColor,
      cardShadowColor: other.cardShadowColor ?? cardShadowColor,
      cardBorderSide: other.cardBorderSide ?? cardBorderSide,
      cardPadding: other.cardPadding,
      hoverShowDelay: other.hoverShowDelay,
      hoverHideDelay: other.hoverHideDelay ?? hoverHideDelay,
      tooltipFadeDuration: other.tooltipFadeDuration,
      enableHover: other.enableHover,
      cardBorderRadius: other.cardBorderRadius,
      cardIcon: other.cardIcon ?? cardIcon,
      cardCloseIcon: other.cardCloseIcon ?? cardCloseIcon,
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
  /// Use it to animate between themes, for example with a `TweenAnimationBuilder`
  /// or from an app-theme transition.
  DashronymTheme lerp(DashronymTheme? other, double t) {
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
      acronymFocusColor: _lerpDerivedColor(
        acronymFocusColor,
        other.acronymFocusColor,
        t,
      ),
      cardWidth: lerpDouble(cardWidth, other.cardWidth, t)!,
      cardElevation: lerpDouble(cardElevation, other.cardElevation, t)!,
      cardColor: _lerpDerivedColor(cardColor, other.cardColor, t),
      cardShadowColor: _lerpDerivedColor(
        cardShadowColor,
        other.cardShadowColor,
        t,
      ),
      cardBorderSide: _lerpNullableBorderSide(
        cardBorderSide,
        other.cardBorderSide,
        t,
      ),
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
      cardIconColor: _lerpDerivedColor(cardIconColor, other.cardIconColor, t),
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashronymTheme && other._properties == _properties;

  @override
  int get hashCode => _properties.hashCode;

  Object get _properties => (
    underline,
    decorationStyle,
    decorationThickness,
    acronymStyle,
    acronymFocusColor,
    cardWidth,
    cardElevation,
    cardColor,
    cardShadowColor,
    cardBorderSide,
    cardPadding,
    hoverShowDelay,
    hoverHideDelay,
    tooltipFadeDuration,
    enableHover,
    cardBorderRadius,
    cardIcon,
    cardCloseIcon,
    cardIconColor,
    cardTitleStyle,
    cardSubtitleStyle,
    cardContentPadding,
    cardMinLeadingWidth,
    tooltipOffset,
    tooltipFadeInCurve,
    tooltipFadeOutCurve,
    tooltipScaleInCurve,
    tooltipScaleOutCurve,
    tooltipScaleBegin,
    tooltipScaleEnd,
    tooltipMinWidth,
    tooltipMaxWidth,
  );

  static T _select<T>(T begin, T end, double t) => t < 0.5 ? begin : end;

  static double? _lerpNullableDouble(double? begin, double? end, double t) {
    if (begin == null || end == null) return _select(begin, end, t);
    return lerpDouble(begin, end, t);
  }

  /// Lerps a color whose null value means "derive it from the host app".
  ///
  /// The derived color isn't known here, so while either side is null the
  /// value switches at the midpoint instead of fading through transparent.
  static Color? _lerpDerivedColor(Color? begin, Color? end, double t) {
    if (begin == null || end == null) return _select(begin, end, t);
    return Color.lerp(begin, end, t);
  }

  static BorderSide? _lerpNullableBorderSide(
    BorderSide? begin,
    BorderSide? end,
    double t,
  ) {
    if (begin == null || end == null) return _select(begin, end, t);
    return BorderSide.lerp(begin, end, t);
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
