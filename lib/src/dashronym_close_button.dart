import 'package:flutter/foundation.dart' show defaultTargetPlatform, internal;
import 'package:flutter/widgets.dart';

import 'dashronym_card_palette.dart';
import 'dashronym_glyphs.dart';

/// The minimum width and height of the close button's touch target.
///
/// Matches Android's 48 x 48 accessibility guideline (and Material's
/// `kMinInteractiveDimension`), which exceeds iOS's 44 x 44 and WCAG 2.5.8.
const double _minTargetSize = 48;

/// The stock tooltip card's close button, built from widgets primitives.
///
/// It keeps the accessibility contract of an icon button: an enabled,
/// focusable button with a tooltip, a 48 x 48 minimum target, activation from
/// Enter and Space (including the web's [ButtonActivateIntent]), and visible
/// hover, pressed and keyboard-focus feedback.
@internal
class DashronymCloseButton extends StatefulWidget {
  /// Creates a close button.
  const DashronymCloseButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.palette,
    this.icon,
  });

  /// Tooltip text, also exposed to assistive technology.
  final String tooltip;

  /// Called when the button is activated.
  final VoidCallback onPressed;

  /// Colors resolved for the card that hosts the button.
  final DashronymCardPalette palette;

  /// Icon to show instead of the built-in close glyph.
  final IconData? icon;

  @override
  State<DashronymCloseButton> createState() => _DashronymCloseButtonState();
}

class _DashronymCloseButtonState extends State<DashronymCloseButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  late final Map<Type, Action<Intent>> _actions = {
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _activate),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
      onInvoke: _activate,
    ),
  };

  Object? _activate(Intent _) {
    widget.onPressed();
    return null;
  }

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.palette.icon;
    final overlayOpacity = _pressed ? 0.10 : (_hovered ? 0.08 : 0.0);
    final glyph = widget.icon == null
        ? DashronymGlyphIcon(DashronymGlyph.close, color: color)
        : Icon(widget.icon, color: color, size: 24);

    final visual = DecoratedBox(
      decoration: BoxDecoration(
        shape: .circle,
        color: overlayOpacity == 0
            ? null
            : color.withValues(alpha: overlayOpacity),
        border: _focused
            ? Border.all(
                color: color,
                width: MediaQuery.highContrastOf(context) ? 3 : 2,
              )
            : null,
      ),
      child: SizedBox.square(dimension: 40, child: Center(child: glyph)),
    );

    return Semantics(
      container: true,
      button: true,
      enabled: true,
      child: RawTooltip(
        semanticsTooltip: widget.tooltip,
        ignorePointer: true,
        tooltipBuilder: (context, animation) => FadeTransition(
          opacity: animation,
          child: _TooltipBubble(widget.tooltip, palette: widget.palette),
        ),
        positionDelegate: (position) => positionDependentBox(
          size: position.overlaySize,
          childSize: position.tooltipSize,
          target: position.target,
          verticalOffset: 24,
          preferBelow: true,
        ),
        child: FocusableActionDetector(
          actions: _actions,
          mouseCursor: WidgetStateMouseCursor.adaptiveClickable,
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          onShowHoverHighlight: (value) => setState(() => _hovered = value),
          child: GestureDetector(
            behavior: .opaque,
            onTap: Feedback.wrapForTap(widget.onPressed, context),
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: _minTargetSize,
                minHeight: _minTargetSize,
              ),
              child: Center(widthFactor: 1, heightFactor: 1, child: visual),
            ),
          ),
        ),
      ),
    );
  }
}

/// The hover and long-press tooltip shown for the close button.
class _TooltipBubble extends StatelessWidget {
  const _TooltipBubble(this.message, {required this.palette});

  final String message;
  final DashronymCardPalette palette;

  @override
  Widget build(BuildContext context) {
    final desktop = switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.linux ||
      TargetPlatform.windows => true,
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.iOS => false,
    };
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: desktop ? 24 : 32),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.bubbleColor,
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: desktop ? 8 : 16,
            vertical: 4,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              message,
              style: TextStyle(
                color: palette.bubbleTextColor,
                fontSize: desktop ? 12 : 14,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
