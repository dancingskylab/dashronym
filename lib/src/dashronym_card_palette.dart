import 'dart:math' as math;

import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/widgets.dart';

import 'dashronym_theme.dart';

/// Colors for the stock tooltip card and the trigger's focus highlight.
///
/// Dashronym does not depend on a design system, so colors the theme leaves
/// unset are derived from widgets-layer signals that Material, Cupertino and
/// custom apps all publish: the ambient [DefaultTextStyle] and [IconTheme],
/// and the [MediaQuery] brightness and contrast settings.
@internal
@immutable
class DashronymCardPalette {
  /// Creates a palette from already-resolved colors.
  const DashronymCardPalette({
    required this.surface,
    required this.foreground,
    required this.icon,
    required this.shadow,
    required this.border,
    required this.bubbleColor,
    required this.bubbleTextColor,
  });

  /// Derives the palette for [theme] from the host around [context].
  ///
  /// [textColorHint] is the trigger's resolved text color. It picks the
  /// surface, because a `DashronymText` can carry its own style, such as light
  /// text on a dark banner. The card's text uses the ambient
  /// [DefaultTextStyle] color, the app's body text, when it contrasts with
  /// the surface.
  factory DashronymCardPalette.resolve(
    BuildContext context,
    DashronymTheme theme, {
    Color? textColorHint,
  }) {
    final ambient = DefaultTextStyle.of(context).style.color;
    final surface =
        theme.cardColor ??
        surfaceFor(
          textColorHint ?? ambient,
          MediaQuery.maybePlatformBrightnessOf(context),
        );
    final isDark = isDarkColor(surface);
    final neutral = isDark ? darkForeground : lightForeground;
    final foreground =
        ambient != null && contrastRatio(ambient, surface) >= minTextContrast
        ? ambient
        : neutral;

    final ambientIcon = IconTheme.of(context).color;
    final icon =
        theme.cardIconColor ??
        (ambientIcon != null &&
                contrastRatio(ambientIcon, surface) >= minIconContrast
            ? ambientIcon
            : foreground);

    final highContrast = MediaQuery.highContrastOf(context);
    return DashronymCardPalette(
      surface: surface,
      foreground: foreground,
      icon: icon,
      shadow: theme.cardShadowColor ?? const Color(0xFF000000),
      border:
          theme.cardBorderSide ??
          (highContrast ? BorderSide(color: foreground) : BorderSide.none),
      bubbleColor: isDark ? lightBubble : darkBubble,
      bubbleTextColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFFFFFFF),
    );
  }

  /// Card background color.
  final Color surface;

  /// Text color for the card's title and description.
  final Color foreground;

  /// Color of the card's icons.
  final Color icon;

  /// Color of the card's elevation shadow.
  final Color shadow;

  /// Outline drawn around the card; [BorderSide.none] for no outline.
  final BorderSide border;

  /// Background of the close button's hover tooltip.
  final Color bubbleColor;

  /// Text color of the close button's hover tooltip.
  final Color bubbleTextColor;

  /// Surface used for dark text, or when nothing suggests a dark host.
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Surface used for light text, or a dark platform without a text color.
  static const Color darkSurface = Color(0xFF2C2C2E);

  /// Text color on [lightSurface] when the host's color lacks contrast.
  static const Color lightForeground = Color(0xFF1F1F1F);

  /// Text color on [darkSurface] when the host's color lacks contrast.
  static const Color darkForeground = Color(0xFFF2F2F2);

  /// Tooltip bubble on a light card: grey at 90% opacity.
  static const Color darkBubble = Color(0xE6616161);

  /// Tooltip bubble on a dark card: white at 90% opacity.
  static const Color lightBubble = Color(0xE6FFFFFF);

  /// Minimum text contrast against the surface (WCAG 1.4.3, AA).
  static const double minTextContrast = 4.5;

  /// Minimum icon contrast against the surface (WCAG 1.4.11, AA).
  static const double minIconContrast = 3;

  /// Relative luminance at which white and black text contrast equally.
  static const double _luminanceMidpoint = 0.179;

  /// Picks a card surface that contrasts with [textColor].
  ///
  /// Light text implies a dark host and a dark card. Without a text color,
  /// [platformBrightness] decides; a missing brightness means light.
  static Color surfaceFor(Color? textColor, Brightness? platformBrightness) {
    if (textColor != null) {
      return isDarkColor(textColor) ? lightSurface : darkSurface;
    }
    return platformBrightness == Brightness.dark ? darkSurface : lightSurface;
  }

  /// Whether [color] is closer to black than to white, ignoring opacity.
  static bool isDarkColor(Color color) =>
      color.computeLuminance() < _luminanceMidpoint;

  /// The WCAG contrast ratio of [foreground], painted over [background].
  static double contrastRatio(Color foreground, Color background) {
    final painted = Color.alphaBlend(foreground, background).computeLuminance();
    final base = background.computeLuminance();
    return (math.max(painted, base) + 0.05) / (math.min(painted, base) + 0.05);
  }

  /// The background painted behind a keyboard-focused acronym.
  ///
  /// Uses [DashronymTheme.acronymFocusColor] when set. Otherwise the trigger's
  /// [textColor] is used at 12% opacity, or 24% in high-contrast mode, so the
  /// highlight stays visible on light and dark hosts alike.
  static Color focusHighlight(
    BuildContext context,
    DashronymTheme theme,
    Color? textColor,
  ) {
    if (theme.acronymFocusColor case final color?) return color;
    final base =
        textColor ??
        DefaultTextStyle.of(context).style.color ??
        const Color(0xFF000000);
    return base.withValues(
      alpha: MediaQuery.highContrastOf(context) ? 0.24 : 0.12,
    );
  }
}
