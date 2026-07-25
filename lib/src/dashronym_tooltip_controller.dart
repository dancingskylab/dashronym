import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Coordinates the active Dashronym tooltip within one widget subtree.
///
/// This is package-internal infrastructure. Applications get a controller
/// automatically through `DashronymScope` or a standalone `DashronymText`.
@internal
class DashronymTooltipController {
  Object? _activeOwner;
  VoidCallback? _dismissActive;

  /// Makes [owner] active and dismisses the previous owner, if any.
  void activate(Object owner, VoidCallback dismiss) {
    if (identical(_activeOwner, owner)) {
      _dismissActive = dismiss;
      return;
    }

    final previousDismiss = _dismissActive;
    _activeOwner = owner;
    _dismissActive = dismiss;
    previousDismiss?.call();
  }

  /// Releases [owner] without disturbing a newer active tooltip.
  void release(Object owner) {
    if (!identical(_activeOwner, owner)) return;
    _activeOwner = null;
    _dismissActive = null;
  }

  void _clear() {
    _activeOwner = null;
    _dismissActive = null;
  }
}

/// Installs one subtree-local [DashronymTooltipController].
@internal
class DashronymTooltipScope extends StatefulWidget {
  /// Creates a scope for tooltip coordination.
  const DashronymTooltipScope({
    super.key,
    required this.child,
  });

  /// The subtree coordinated by this scope.
  final Widget child;

  /// Returns the nearest controller, or `null` when no scope is installed.
  static DashronymTooltipController? maybeControllerOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<
          _DashronymTooltipControllerProvider
        >()
        ?.controller;
  }

  @override
  State<DashronymTooltipScope> createState() => _DashronymTooltipScopeState();
}

class _DashronymTooltipScopeState extends State<DashronymTooltipScope> {
  final DashronymTooltipController _controller = DashronymTooltipController();

  @override
  void dispose() {
    _controller._clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DashronymTooltipControllerProvider(
      controller: _controller,
      child: widget.child,
    );
  }
}

class _DashronymTooltipControllerProvider extends InheritedWidget {
  const _DashronymTooltipControllerProvider({
    required this.controller,
    required super.child,
  });

  final DashronymTooltipController controller;

  @override
  bool updateShouldNotify(_DashronymTooltipControllerProvider oldWidget) =>
      !identical(controller, oldWidget.controller);
}
