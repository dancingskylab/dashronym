import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Signature used by the tooltip interaction coordinator to hide a surface.
@internal
typedef DashronymTooltipHideCallback =
    void Function({
      bool immediate,
      bool announce,
      bool restoreFocus,
    });

/// Owns the focus and hover interaction lifecycle for one inline trigger.
@internal
class DashronymTooltipInteraction {
  /// Creates an interaction coordinator.
  DashronymTooltipInteraction({
    required this._showTooltip,
    required this._hideTooltip,
    required this._isAlive,
    required this._hoverShowDelay,
    required this._hoverHideDelay,
  });

  final VoidCallback _showTooltip;
  final DashronymTooltipHideCallback _hideTooltip;
  final bool Function() _isAlive;

  /// Focus node for the inline acronym trigger.
  final FocusNode triggerFocusNode = FocusNode(
    debugLabel: 'DashronymInline',
  );

  /// Focus scope shared by controls inside the tooltip.
  ///
  /// [TraversalEdgeBehavior.parentScope] lets Tab/Shift+Tab escape to the
  /// next sibling trigger once traversal runs out of tooltip controls,
  /// instead of looping forever inside a scope that may hold only one
  /// focusable control (the close button).
  final FocusScopeNode tooltipFocusScope = FocusScopeNode(
    debugLabel: 'DashronymTooltip',
    traversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
  );

  Duration _hoverShowDelay;
  Duration _hoverHideDelay;
  Timer? _hoverShowTimer;
  Timer? _hoverHideTimer;
  bool _hoveringTrigger = false;
  bool _hoveringTooltip = false;
  bool _suppressFocusShow = false;
  bool _disposed = false;

  /// Updates hover timing after a theme change.
  void updateHoverDelays({
    required Duration showDelay,
    required Duration hideDelay,
  }) {
    _hoverShowDelay = showDelay;
    _hoverHideDelay = hideDelay;
  }

  /// Cancels pending hover transitions.
  void cancelPending() {
    _hoverShowTimer?.cancel();
    _hoverHideTimer?.cancel();
  }

  /// Handles a pointer entering the trigger.
  void handleTriggerEnter() {
    if (_disposed) return;
    _hoveringTrigger = true;
    cancelPending();
    _hoverShowTimer = Timer(_hoverShowDelay, () {
      if (_isAlive() && _hoveringTrigger) {
        _showTooltip();
      }
    });
  }

  /// Handles a pointer leaving the trigger.
  void handleTriggerExit() {
    if (_disposed) return;
    _hoveringTrigger = false;
    _hoverShowTimer?.cancel();
    _scheduleHoverHide();
  }

  /// Handles a pointer entering the tooltip surface.
  void handleTooltipEnter() {
    if (_disposed) return;
    _hoveringTooltip = true;
    _hoverHideTimer?.cancel();
  }

  /// Handles a pointer leaving the tooltip surface.
  void handleTooltipExit() {
    if (_disposed) return;
    _hoveringTooltip = false;
    _scheduleHoverHide();
  }

  /// Handles pointer activation on the inline trigger.
  void handleTriggerTap({required bool wasVisible}) {
    if (!triggerFocusNode.hasFocus) {
      triggerFocusNode.requestFocus();
    }
    if (wasVisible) {
      _hideTooltip();
    } else {
      _showTooltip();
    }
  }

  /// Handles focus changes on the inline trigger.
  void handleTriggerFocusChange(bool focused) {
    if (focused) {
      _hoverHideTimer?.cancel();
      if (!_suppressFocusShow) {
        _showTooltip();
      }
    } else {
      _handleFocusLoss();
    }
  }

  /// Handles focus changes within the tooltip surface.
  void handleTooltipFocusChange(bool focused) {
    if (focused) {
      _hoverHideTimer?.cancel();
    } else {
      _handleFocusLoss();
    }
  }

  /// Restores focus to the trigger without reopening the tooltip.
  void restoreTriggerFocus() {
    if (!_isAlive() || !triggerFocusNode.canRequestFocus) return;
    _suppressFocusShow = true;
    triggerFocusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        _suppressFocusShow = false;
      }
    });
  }

  void _scheduleHoverHide() {
    _hoverHideTimer?.cancel();
    _hoverHideTimer = Timer(_hoverHideDelay, () {
      if (!_isAlive() ||
          _hoveringTrigger ||
          _hoveringTooltip ||
          triggerFocusNode.hasFocus ||
          tooltipFocusScope.hasFocus) {
        return;
      }
      _hideTooltip();
    });
  }

  void _handleFocusLoss() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isAlive() ||
          triggerFocusNode.hasFocus ||
          tooltipFocusScope.hasFocus ||
          _hoveringTrigger ||
          _hoveringTooltip) {
        return;
      }
      _hideTooltip();
    });
  }

  /// Releases focus nodes and pending timers.
  void dispose() {
    _disposed = true;
    cancelPending();
    _hoveringTrigger = false;
    _hoveringTooltip = false;
    triggerFocusNode.dispose();
    tooltipFocusScope.dispose();
  }
}
