import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'dashronym_theme.dart';

/// Shared helpers for clamping tooltip content within the visible viewport.
///
/// The resolver is used by both the stock Dashronym tooltip card and any custom
/// tooltip builders supplied to `AcronymInline`. It projects the overlay, media
/// query and theme caps into a single [BoxConstraints] so tooltip content never
/// paints outside the window gutters or the on-screen keyboard.
class TooltipConstraintsResolver {
  const TooltipConstraintsResolver._(); // coverage:ignore-line

  /// Default outer gutter applied on either horizontal edge.
  static const double outerGutter = 8.0;

  /// Calculates constraints that keep the tooltip inside the viewport.
  ///
  /// The algorithm considers:
  ///
  /// * the parent layout [constraints] (typically the overlay),
  /// * safe-area padding obtained from [mediaQuery], and
  /// * the on-screen keyboard represented by [MediaQueryData.viewInsets], and
  /// * theme-provided caps on width (see [DashronymTheme.tooltipMaxWidth]).
  ///
  /// The returned constraints always have a `minWidth` that is `<= maxWidth`,
  /// collapsing the minimum when the available width is too tight for the
  /// theme-requested minimum.
  static BoxConstraints resolve({
    required BoxConstraints constraints,
    required MediaQueryData? mediaQuery,
    required DashronymTheme theme,
  }) {
    final padding = mediaQuery?.padding ?? EdgeInsets.zero;
    final screenWidth = mediaQuery?.size.width ?? double.infinity;
    final screenHeight = mediaQuery?.size.height ?? double.infinity;
    final keyboardInset = math.max(
      0.0,
      mediaQuery?.viewInsets.bottom ?? 0.0,
    );
    final orientation = mediaQuery?.orientation ?? Orientation.portrait;

    // A locally overridden MediaQueryData is sometimes created with only
    // accessibility fields (for example, a text scaler), leaving its size at
    // Size.zero. Treat that as unknown and rely on the real overlay
    // constraints instead of collapsing the tooltip to zero width.
    final safeScreenWidth = screenWidth.isFinite && screenWidth > 0
        ? screenWidth - padding.left - padding.right
        : double.infinity;
    double viewportCap = safeScreenWidth.isFinite
        ? safeScreenWidth - outerGutter * 2
        : double.infinity;
    if (viewportCap.isFinite && viewportCap < 0) {
      viewportCap = 0;
    }

    double overlayCap = constraints.maxWidth.isFinite
        ? constraints.maxWidth - outerGutter * 2
        : double.infinity;
    if (overlayCap.isFinite && overlayCap < 0) {
      overlayCap = 0;
    }

    final themeCap =
        theme.tooltipMaxWidth ??
        (orientation == Orientation.portrait
            ? theme.cardWidth
            : double.infinity);

    double maxWidth = double.infinity;
    for (final candidate in [viewportCap, overlayCap, themeCap]) {
      if (candidate.isFinite) {
        maxWidth = maxWidth.isFinite
            ? math.min(maxWidth, candidate)
            : candidate;
      }
    }
    if (maxWidth.isFinite && maxWidth < 0) {
      maxWidth = 0;
    }

    final orientationCap = orientation == Orientation.portrait ? 360.0 : 600.0;
    if (maxWidth.isFinite) {
      maxWidth = math.min(maxWidth, orientationCap);
    } else {
      maxWidth = orientationCap;
    }

    double minWidth = theme.tooltipMinWidth ?? 0;
    if (minWidth > 0 && maxWidth.isFinite && minWidth > maxWidth) {
      minWidth = maxWidth;
    }

    final safeScreenHeight = screenHeight.isFinite && screenHeight > 0
        ? screenHeight -
              padding.top -
              padding.bottom -
              math.min(keyboardInset, screenHeight)
        : double.infinity;
    double viewportHeightCap = safeScreenHeight.isFinite
        ? safeScreenHeight - outerGutter * 2
        : double.infinity;
    if (viewportHeightCap.isFinite && viewportHeightCap < 0) {
      viewportHeightCap = 0;
    }

    double overlayHeightCap = constraints.maxHeight.isFinite
        ? constraints.maxHeight - outerGutter * 2
        : double.infinity;
    if (overlayHeightCap.isFinite && overlayHeightCap < 0) {
      overlayHeightCap = 0;
    }

    double maxHeight = double.infinity;
    for (final candidate in [viewportHeightCap, overlayHeightCap]) {
      if (candidate.isFinite) {
        maxHeight = maxHeight.isFinite
            ? math.min(maxHeight, candidate)
            : candidate;
      }
    }

    return BoxConstraints(
      minWidth: minWidth > 0 ? minWidth : 0,
      maxWidth: maxWidth.isFinite ? maxWidth : double.infinity,
      maxHeight: maxHeight.isFinite ? maxHeight : double.infinity,
    );
  }
}

/// Shares already-resolved tooltip constraints with descendants.
///
/// The stock tooltip card uses this scope to avoid resolving and applying the
/// same viewport constraints a second time when it is hosted by
/// `AcronymInline`. Standalone cards still resolve their own constraints.
class TooltipConstraintScope extends InheritedWidget {
  /// Creates a scope containing [constraints].
  const TooltipConstraintScope({
    super.key,
    required this.constraints,
    required super.child,
  });

  /// The viewport-safe constraints applied by the nearest tooltip host.
  final BoxConstraints constraints;

  /// Returns the nearest resolved constraints, if any.
  static BoxConstraints? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TooltipConstraintScope>()
        ?.constraints;
  }

  @override
  bool updateShouldNotify(TooltipConstraintScope oldWidget) =>
      constraints != oldWidget.constraints;
}
