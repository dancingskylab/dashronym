import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'dashronym_theme.dart';
import 'dashronym_tooltip_constraints.dart';
import 'dashronym_tooltip_positioner.dart';

/// Composes the root-overlay surface for one Dashronym tooltip.
@internal
class DashronymTooltipOverlay extends StatelessWidget {
  /// Creates an overlay around [child].
  const DashronymTooltipOverlay({
    super.key,
    required this.controller,
    required this.theme,
    required this.opacity,
    required this.scale,
    required this.tooltipFocusScope,
    required this.tooltipBuilder,
    required this.makeScrollable,
    required this.onDismiss,
    required this.onOutsideDismiss,
    required this.onTooltipEnter,
    required this.onTooltipExit,
    required this.onTooltipFocusChange,
    required this.child,
  });

  /// Controls insertion and removal of the overlay portal.
  final OverlayPortalController controller;

  /// Effective tooltip theme.
  final DashronymTheme theme;

  /// Fade animation for the tooltip surface.
  final Animation<double> opacity;

  /// Scale animation for the tooltip surface.
  final Animation<double> scale;

  /// Focus scope for controls inside the tooltip.
  final FocusScopeNode tooltipFocusScope;

  /// Builds the stock or custom tooltip in the overlay context.
  final WidgetBuilder tooltipBuilder;

  /// Whether the tooltip host should make custom content scrollable.
  final bool makeScrollable;

  /// Dismisses the tooltip and restores trigger focus.
  final VoidCallback onDismiss;

  /// Dismisses the tooltip after a pointer action outside its surface.
  final VoidCallback onOutsideDismiss;

  /// Called when a pointer enters the tooltip.
  final VoidCallback onTooltipEnter;

  /// Called when a pointer exits the tooltip.
  final VoidCallback onTooltipExit;

  /// Reports focus changes inside the tooltip.
  final ValueChanged<bool> onTooltipFocusChange;

  /// Inline trigger wrapped by the overlay portal.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: controller,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: (overlayContext, layoutInfo) {
        return _buildOverlay(context, overlayContext, layoutInfo);
      },
      child: child,
    );
  }

  Widget _buildOverlay(
    BuildContext triggerContext,
    BuildContext overlayContext,
    OverlayChildLayoutInfo layoutInfo,
  ) {
    // The overlay context carries the trigger's MediaQuery with the overlay's
    // own padding and view insets (Flutter 3.44+). Prefer it: a scaffold
    // strips the keyboard inset and status bar padding from its body, so the
    // trigger's MediaQuery would let the card slide under them.
    final mediaQuery = MediaQuery.maybeOf(overlayContext);
    final anchorRect = MatrixUtils.transformRect(
      layoutInfo.childPaintTransform,
      Offset.zero & layoutInfo.childSize,
    );
    final tooltip = DashronymTooltipViewport(
      theme: theme,
      mediaQuery: mediaQuery,
      makeScrollable: makeScrollable,
      child: tooltipBuilder(overlayContext),
    );

    // Escape is handled by DashronymInline's early key handler while the
    // tooltip is visible. This action serves DismissIntent from other
    // shortcuts, restoring focus to the trigger.
    Widget result = Actions(
      actions: <Type, Action<Intent>>{
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            onDismiss();
            return null;
          },
        ),
      },
      // DashronymInline orders this scope right after the trigger. Without the
      // order, the scope sorts by its rect, which spans the whole overlay, and
      // lands before the trigger, so Tab from the trigger would skip the card.
      child: FocusTraversalOrder(
        order: const NumericFocusOrder(1),
        child: FocusScope(
          node: tooltipFocusScope,
          onFocusChange: onTooltipFocusChange,
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: onOutsideDismiss,
                    onSecondaryTap: onOutsideDismiss,
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomSingleChildLayout(
                  delegate: DashronymTooltipLayoutDelegate(
                    anchorRect: anchorRect,
                    theme: theme,
                    padding: mediaQuery?.padding ?? EdgeInsets.zero,
                    keyboardInset: mediaQuery?.viewInsets.bottom ?? 0.0,
                    direction: Directionality.of(triggerContext),
                    viewportMargin: DashronymTooltipConstraints.outerGutter,
                  ),
                  child: MouseRegion(
                    opaque: false,
                    onEnter: theme.enableHover ? (_) => onTooltipEnter() : null,
                    onExit: theme.enableHover ? (_) => onTooltipExit() : null,
                    child: FadeTransition(
                      opacity: opacity,
                      child: ScaleTransition(
                        // Reduce Motion asks for cross-fades instead of motion, so keep
                        // the card at full size and let it only fade.
                        scale: (mediaQuery?.reduceMotion ?? false)
                            ? kAlwaysCompleteAnimation
                            : scale,
                        child: tooltip,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // The layout-builder portal provides root-overlay constraints even when
    // the source lives in a tightly constrained WidgetSpan.
    return Positioned.fill(child: result);
  }
}
