import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'dashronym_theme.dart';

/// Computes follower offsets for the inline acronym tooltip overlay.
///
/// This helper centralizes the geometry calculations that keep the tooltip
/// within the visible viewport. It accounts for safe areas, keyboard insets,
/// and text direction so `_DashronymInlineState` can focus on interactions.
class DashronymTooltipPositioner {
  const DashronymTooltipPositioner._(); // coverage:ignore-line

  /// Returns the baseline follower offset relative to the anchor before any
  /// viewport clamping is applied.
  ///
  /// The result positions the tooltip immediately below the inline trigger.
  ///
  /// Horizontal placement is refined later in [resolveFollowerOffset] once the
  /// tooltip size is known; here we only apply the vertical component from
  /// [DashronymTheme.tooltipOffset].
  static Offset baseFollowerOffset({
    required Size anchorSize,
    required DashronymTheme theme,
    required TextDirection direction,
  }) {
    return Offset(
      theme.tooltipOffset.dx,
      anchorSize.height + theme.tooltipOffset.dy,
    );
  }

  /// Resolves the final follower offset relative to the anchor’s top-left after
  /// enforcing viewport margins, safe-area padding, and keyboard insets.
  ///
  /// When the tooltip would overflow to the right, it clamps within the overlay
  /// width and nudges slightly inward so the card does not hug the edge. If
  /// there is not enough space below, it flips above the anchor while
  /// respecting the configured tooltip offsets and viewport margin.
  ///
  /// The [overlaySize] is the size of the overlay render box, [anchorTopLeft]
  /// and [anchorSize] describe the trigger position and dimensions, and
  /// [tooltipSize] provides the tooltip card’s size. The [padding] should
  /// describe safe-area insets, while [keyboardInset] reserves space for an
  /// on-screen keyboard. Use [viewportMargin] to keep the tooltip away from the
  /// overlay edges.
  static Offset resolveFollowerOffset({
    required Size overlaySize,
    required Offset anchorTopLeft,
    required Size anchorSize,
    required Size tooltipSize,
    required DashronymTheme theme,
    required EdgeInsets padding,
    required double keyboardInset,
    required TextDirection direction,
    double viewportMargin = 8.0,
  }) {
    final baseOffset = baseFollowerOffset(
      anchorSize: anchorSize,
      theme: theme,
      direction: direction,
    );

    final availableWidth = overlaySize.width - padding.left - padding.right;
    final desiredHorizontalMargin = math.max(0.0, viewportMargin);
    final maxHorizontalMargin = math.max(
      0.0,
      (availableWidth - tooltipSize.width) / 2.0,
    );
    final horizontalMargin = math.min(
      desiredHorizontalMargin,
      maxHorizontalMargin,
    );

    final minLeft = padding.left + horizontalMargin;
    final maxLeft =
        overlaySize.width -
        padding.right -
        horizontalMargin -
        tooltipSize.width;

    final effectiveKeyboardInset = keyboardInset
        .clamp(0.0, math.max(0.0, overlaySize.height - padding.top))
        .toDouble();
    final availableHeight =
        overlaySize.height -
        padding.top -
        padding.bottom -
        effectiveKeyboardInset;
    final desiredVerticalMargin = math.max(0.0, viewportMargin);
    final maxVerticalMargin = math.max(
      0.0,
      (availableHeight - tooltipSize.height) / 2.0,
    );
    final verticalMargin = math.min(desiredVerticalMargin, maxVerticalMargin);

    final safeTop = math.min(
      overlaySize.height,
      padding.top + verticalMargin,
    );
    final rawSafeBottom =
        overlaySize.height -
        padding.bottom -
        effectiveKeyboardInset -
        verticalMargin;
    final safeBottomLimit = math.max(safeTop, rawSafeBottom);

    const edgeNudge = 8.0;
    final desiredLeft = direction == TextDirection.ltr
        ? anchorTopLeft.dx + baseOffset.dx
        : anchorTopLeft.dx +
              anchorSize.width -
              tooltipSize.width -
              theme.tooltipOffset.dx;
    double left = desiredLeft;
    if (minLeft <= maxLeft) {
      left = left.clamp(minLeft, maxLeft).toDouble();

      if (desiredLeft < minLeft && left == minLeft) {
        final available = math.max(0.0, maxLeft - left);
        left += math.min(edgeNudge, available);
      } else if (desiredLeft > maxLeft && left == maxLeft) {
        final available = math.max(0.0, left - minLeft);
        left -= math.min(edgeNudge, available);
      }
    } else {
      left = padding.left;
    }

    final desiredBelow = anchorTopLeft.dy + baseOffset.dy;
    double top = desiredBelow;
    final fitsBelow = desiredBelow + tooltipSize.height <= safeBottomLimit;
    final desiredAbove =
        anchorTopLeft.dy - tooltipSize.height - theme.tooltipOffset.dy;
    final fitsAbove = desiredAbove >= safeTop;

    if (safeBottomLimit <= safeTop) {
      top = safeTop;
    } else if (!fitsBelow && fitsAbove) {
      top = desiredAbove;
    } else {
      top = math.min(desiredBelow, safeBottomLimit - tooltipSize.height);
      top = math.max(top, safeTop);
    }

    return Offset(left - anchorTopLeft.dx, top - anchorTopLeft.dy);
  }
}
