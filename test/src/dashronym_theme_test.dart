import 'package:dashronym/dashronym.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Design-system-neutral stand-ins for icons and colors.
const _star = IconData(0xe001);
const _cancel = IconData(0xe002);
const _indigo = Color(0xFF3F51B5);
const _blue = Color(0xFF2196F3);
const _surface = Color(0xFFFFFBFE);
const _shadow = Color(0xFF101010);
const _outline = BorderSide(color: Color(0xFF79747E), width: 2);
const _focus = Color(0x1F000000);

void main() {
  test('DashronymTheme exposes default values', () {
    const theme = DashronymTheme();

    expect(theme.underline, isTrue);
    expect(theme.decorationStyle, TextDecorationStyle.dotted);
    expect(theme.cardWidth, 320);
    expect(theme.cardElevation, 8);
    expect(theme.hoverShowDelay, const Duration(milliseconds: 250));
    expect(theme.hoverHideDelay, isNull);
    expect(theme.enableHover, isTrue);
    expect(theme.cardBorderRadius, 12);
    // Null icons and colors mean "derive from the host app".
    expect(theme.cardIcon, isNull);
    expect(theme.cardCloseIcon, isNull);
    expect(theme.cardColor, isNull);
    expect(theme.cardShadowColor, isNull);
    expect(theme.cardBorderSide, isNull);
    expect(theme.acronymFocusColor, isNull);
    expect(theme.tooltipOffset, const Offset(0, 6));
    expect(theme.tooltipFadeDuration, const Duration(milliseconds: 150));
    expect(theme.tooltipFadeInCurve, Curves.easeOut);
    expect(theme.tooltipFadeOutCurve, Curves.easeIn);
    expect(theme.tooltipScaleInCurve, Curves.easeOut);
    expect(theme.tooltipScaleOutCurve, Curves.easeIn);
    expect(theme.tooltipScaleBegin, 0.95);
    expect(theme.tooltipScaleEnd, 1.0);
    expect(theme.tooltipMinWidth, isNull);
    expect(theme.tooltipMaxWidth, isNull);
  });

  test('DashronymTheme accepts custom overrides', () {
    const theme = DashronymTheme(
      underline: false,
      decorationStyle: TextDecorationStyle.double,
      acronymFocusColor: _focus,
      cardWidth: 200,
      cardElevation: 4,
      cardColor: _surface,
      cardShadowColor: _shadow,
      cardBorderSide: _outline,
      hoverShowDelay: Duration.zero,
      hoverHideDelay: Duration(milliseconds: 400),
      tooltipFadeDuration: Duration(milliseconds: 250),
      enableHover: false,
      cardBorderRadius: 4,
      cardIcon: _star,
      cardCloseIcon: _cancel,
      tooltipOffset: Offset(2, 8),
      tooltipFadeInCurve: Curves.easeInOut,
      tooltipFadeOutCurve: Curves.easeInExpo,
      tooltipScaleInCurve: Curves.decelerate,
      tooltipScaleOutCurve: Curves.linear,
      tooltipScaleBegin: 0.8,
      tooltipScaleEnd: 1.1,
      tooltipMinWidth: 120,
      tooltipMaxWidth: 260,
    );

    expect(theme.underline, isFalse);
    expect(theme.decorationStyle, TextDecorationStyle.double);
    expect(theme.acronymFocusColor, _focus);
    expect(theme.cardWidth, 200);
    expect(theme.cardElevation, 4);
    expect(theme.cardColor, _surface);
    expect(theme.cardShadowColor, _shadow);
    expect(theme.cardBorderSide, _outline);
    expect(theme.hoverShowDelay, Duration.zero);
    expect(theme.hoverHideDelay, const Duration(milliseconds: 400));
    expect(theme.enableHover, isFalse);
    expect(theme.cardBorderRadius, 4);
    expect(theme.cardIcon, _star);
    expect(theme.cardCloseIcon, _cancel);
    expect(theme.tooltipOffset, const Offset(2, 8));
    expect(theme.tooltipFadeDuration, const Duration(milliseconds: 250));
    expect(theme.tooltipFadeInCurve, Curves.easeInOut);
    expect(theme.tooltipFadeOutCurve, Curves.easeInExpo);
    expect(theme.tooltipScaleInCurve, Curves.decelerate);
    expect(theme.tooltipScaleOutCurve, Curves.linear);
    expect(theme.tooltipScaleBegin, 0.8);
    expect(theme.tooltipScaleEnd, 1.1);
    expect(theme.tooltipMinWidth, 120);
    expect(theme.tooltipMaxWidth, 260);
  });

  test('DashronymTheme.copyWith overrides selected fields', () {
    const base = DashronymTheme(
      hoverHideDelay: Duration(milliseconds: 300),
      tooltipScaleBegin: 0.9,
      tooltipMinWidth: 100,
    );

    final copy = base.copyWith(
      underline: false,
      hoverHideDelay: null,
      tooltipScaleEnd: 1.05,
      tooltipMaxWidth: 280,
      cardColor: _surface,
      cardShadowColor: _shadow,
      cardBorderSide: _outline,
      acronymFocusColor: _focus,
      cardIcon: _star,
      cardCloseIcon: _cancel,
    );

    expect(copy.underline, isFalse);
    expect(copy.hoverHideDelay, isNull);
    expect(copy.tooltipScaleBegin, 0.9);
    expect(copy.tooltipScaleEnd, 1.05);
    expect(copy.tooltipMinWidth, 100);
    expect(copy.tooltipMaxWidth, 280);
    expect(copy.cardColor, _surface);
    expect(copy.cardShadowColor, _shadow);
    expect(copy.cardBorderSide, _outline);
    expect(copy.acronymFocusColor, _focus);
    expect(copy.cardIcon, _star);
    expect(copy.cardCloseIcon, _cancel);
  });

  test('DashronymTheme.copyWith retains hoverHideDelay when omitted', () {
    const base = DashronymTheme(hoverHideDelay: Duration(milliseconds: 120));
    final copy = base.copyWith(cardWidth: 400);
    expect(copy.hoverHideDelay, const Duration(milliseconds: 120));
    expect(copy.cardWidth, 400);
  });

  test('DashronymTheme.copyWith can explicitly clear nullable values', () {
    const base = DashronymTheme(
      decorationThickness: 2,
      acronymStyle: TextStyle(fontWeight: FontWeight.bold),
      acronymFocusColor: _focus,
      cardColor: _surface,
      cardShadowColor: _shadow,
      cardBorderSide: _outline,
      hoverHideDelay: Duration(milliseconds: 120),
      cardIcon: _star,
      cardCloseIcon: _cancel,
      cardIconColor: _blue,
      cardTitleStyle: TextStyle(fontWeight: FontWeight.bold),
      cardSubtitleStyle: TextStyle(fontStyle: FontStyle.italic),
      tooltipMinWidth: 100,
      tooltipMaxWidth: 300,
    );

    final copy = base.copyWith(
      clearDecorationThickness: true,
      clearAcronymStyle: true,
      clearAcronymFocusColor: true,
      clearCardColor: true,
      clearCardShadowColor: true,
      clearCardBorderSide: true,
      hoverHideDelay: null,
      clearCardIcon: true,
      clearCardCloseIcon: true,
      clearCardIconColor: true,
      clearCardTitleStyle: true,
      clearCardSubtitleStyle: true,
      clearTooltipMinWidth: true,
      clearTooltipMaxWidth: true,
    );

    expect(copy.decorationThickness, isNull);
    expect(copy.acronymStyle, isNull);
    expect(copy.acronymFocusColor, isNull);
    expect(copy.cardColor, isNull);
    expect(copy.cardShadowColor, isNull);
    expect(copy.cardBorderSide, isNull);
    expect(copy.hoverHideDelay, isNull);
    expect(copy.cardIcon, isNull);
    expect(copy.cardCloseIcon, isNull);
    expect(copy.cardIconColor, isNull);
    expect(copy.cardTitleStyle, isNull);
    expect(copy.cardSubtitleStyle, isNull);
    expect(copy.tooltipMinWidth, isNull);
    expect(copy.tooltipMaxWidth, isNull);
  });

  test('DashronymTheme.copyWith rejects replacement and clear conflicts', () {
    const base = DashronymTheme();

    expect(
      () => base.copyWith(tooltipMaxWidth: 320, clearTooltipMaxWidth: true),
      throwsArgumentError,
    );
    expect(
      () => base.copyWith(cardColor: _surface, clearCardColor: true),
      throwsArgumentError,
    );
    expect(
      () => base.copyWith(cardIcon: _star, clearCardIcon: true),
      throwsArgumentError,
    );
    expect(
      () => base.copyWith(cardBorderSide: _outline, clearCardBorderSide: true),
      throwsArgumentError,
    );
  });

  test('DashronymTheme.merge prefers other values when provided', () {
    const base = DashronymTheme(
      cardWidth: 320,
      cardColor: _surface,
      cardIcon: _star,
    );
    const other = DashronymTheme(
      cardWidth: 280,
      tooltipScaleBegin: 0.85,
      tooltipScaleEnd: 1.0,
      cardShadowColor: _shadow,
      cardCloseIcon: _cancel,
    );

    final merged = base.merge(other);

    expect(merged.cardWidth, 280);
    expect(merged.tooltipScaleBegin, 0.85);
    expect(merged.tooltipScaleEnd, 1.0);
    // Nullable values the other theme leaves unset are kept.
    expect(merged.cardColor, _surface);
    expect(merged.cardIcon, _star);
    expect(merged.cardShadowColor, _shadow);
    expect(merged.cardCloseIcon, _cancel);
    expect(base.merge(null), same(base));
  });

  test('DashronymTheme uses value equality', () {
    const first = DashronymTheme(
      acronymStyle: TextStyle(color: _indigo),
      cardWidth: 280,
      cardColor: _surface,
      cardBorderSide: _outline,
      hoverHideDelay: Duration(milliseconds: 120),
      tooltipMaxWidth: 360,
    );
    const equal = DashronymTheme(
      acronymStyle: TextStyle(color: _indigo),
      cardWidth: 280,
      cardColor: _surface,
      cardBorderSide: _outline,
      hoverHideDelay: Duration(milliseconds: 120),
      tooltipMaxWidth: 360,
    );

    expect(first, equal);
    expect(first.hashCode, equal.hashCode);
    expect(first, isNot(const DashronymTheme(cardWidth: 281)));
    expect(first, isNot(first.copyWith(cardColor: _shadow)));
    expect(first, isNot(first.copyWith(clearCardBorderSide: true)));
  });

  test('DashronymTheme.lerp interpolates animatable values', () {
    const begin = DashronymTheme(
      cardWidth: 200,
      cardElevation: 2,
      cardColor: Color(0xFF000000),
      cardBorderSide: BorderSide(width: 1),
      tooltipFadeDuration: Duration(milliseconds: 100),
      tooltipOffset: Offset.zero,
      tooltipScaleBegin: 0.8,
      tooltipScaleEnd: 1,
    );
    const end = DashronymTheme(
      underline: false,
      cardWidth: 300,
      cardElevation: 6,
      cardColor: Color(0xFFFFFFFF),
      cardBorderSide: BorderSide(width: 3),
      cardIcon: _star,
      tooltipFadeDuration: Duration(milliseconds: 300),
      tooltipOffset: Offset(10, 20),
      tooltipScaleBegin: 1,
      tooltipScaleEnd: 1.2,
    );

    final midpoint = begin.lerp(end, 0.5);

    expect(midpoint.underline, isFalse);
    expect(midpoint.cardWidth, 250);
    expect(midpoint.cardElevation, 4);
    expect(midpoint.cardColor, Color.lerp(begin.cardColor, end.cardColor, 0.5));
    expect(midpoint.cardBorderSide?.width, 2);
    expect(midpoint.cardIcon, _star);
    expect(
      midpoint.tooltipFadeDuration,
      const Duration(milliseconds: 200),
    );
    expect(midpoint.tooltipOffset, const Offset(5, 10));
    expect(midpoint.tooltipScaleBegin, 0.9);
    expect(midpoint.tooltipScaleEnd, 1.1);
    expect(begin.lerp(null, 0.5), same(begin));
  });

  test('DashronymTheme.lerp switches nullable borders at the midpoint', () {
    const withBorder = DashronymTheme(cardBorderSide: _outline);
    const withoutBorder = DashronymTheme();

    expect(withBorder.lerp(withoutBorder, 0.4).cardBorderSide, _outline);
    expect(withBorder.lerp(withoutBorder, 0.6).cardBorderSide, isNull);
  });

  test('DashronymTheme.lerp interpolates nullable values when both exist', () {
    const begin = DashronymTheme(
      decorationThickness: 1,
      hoverHideDelay: Duration(milliseconds: 100),
      tooltipMinWidth: 100,
    );
    const end = DashronymTheme(
      decorationThickness: 3,
      hoverHideDelay: Duration(milliseconds: 300),
      tooltipMinWidth: 200,
    );

    final midpoint = begin.lerp(end, 0.5);

    expect(midpoint.decorationThickness, 2);
    expect(midpoint.hoverHideDelay, const Duration(milliseconds: 200));
    expect(midpoint.tooltipMinWidth, 150);
  });
}
