/// Dashronym inline trigger widgets and tooltip surface integration.
///
/// This file defines:
///
/// * [DashronymInline] — an inline, accessible trigger that shows a tooltip for a term.
/// * [DashronymTooltipDetails] — the metadata passed to a custom [DashronymTooltipBuilder].
/// * [DashronymTooltipBuilder] — a typedef for building a custom tooltip widget.
///
/// ### Sizing behavior at a glance
/// The overlay resolves one set of width and height constraints from the
/// trigger's viewport, safe areas, keyboard insets, and theme. The stock card
/// scrolls oversized content; custom tooltips receive the same bounded,
/// scrollable host.
///
/// ### Example
/// ```dart
/// Wrap(
///   crossAxisAlignment: WrapCrossAlignment.center,
///   spacing: 4,
///   children: [
///     const Text('Install the'),
///     DashronymInline(
///       acronym: 'SDK',
///       description: 'Software Development Kit',
///       theme: myDashronymTheme,
///       textStyle: Theme.of(context).textTheme.bodyMedium,
///     ),
///     const Text('before continuing.'),
///   ],
/// );
/// ```
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/widgets.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'dashronym_card_palette.dart';
import 'dashronym_localizations.dart';
import 'dashronym_theme.dart';
import 'dashronym_tooltip_card.dart';
import 'dashronym_tooltip_controller.dart';
import 'dashronym_tooltip_interaction.dart';
import 'dashronym_tooltip_overlay.dart';

/// Signature used to build custom tooltip content for `DashronymText`.
///
/// The function receives the current [BuildContext] and a [DashronymTooltipDetails]
/// object describing the selected term. Return any widget you want to display as the
/// tooltip body (e.g. a custom card, sheet, etc.).
///
/// ### Example
/// ```dart
/// DashronymText(
///   'The (CI) build passed.',
///   registry: DashronymRegistry({
///     'CI': 'Continuous Integration',
///   }),
///   tooltipBuilder: (context, details) {
///     return Material(
///       elevation: details.theme.cardElevation,
///       borderRadius: BorderRadius.circular(
///         details.theme.cardBorderRadius,
///       ),
///       child: ListTile(
///         title: Text(details.acronym),
///         subtitle: Text(details.description),
///         trailing: IconButton(
///           tooltip: DashronymLocalizations.of(
///             context,
///           ).closeButtonTooltip(details.acronym),
///           onPressed: details.hideTooltip,
///           icon: const Icon(Icons.close),
///         ),
///       ),
///     );
///   },
/// );
/// ```
typedef DashronymTooltipBuilder = Widget Function(
  BuildContext context,
  DashronymTooltipDetails details,
);

/// Data surfaced to [DashronymTooltipBuilder] implementations.
class DashronymTooltipDetails {
  /// Creates tooltip metadata provided to custom tooltip builders.
  const DashronymTooltipDetails({
    required this.acronym,
    required this.description,
    required this.theme,
    required this.hideTooltip,
  });

  /// The acronym shown by the inline trigger.
  final String acronym;

  /// The long-form description associated with [acronym].
  final String description;

  /// The effective theme driving tooltip styling.
  final DashronymTheme theme;

  /// Callback that hides the tooltip overlay.
  final VoidCallback hideTooltip;
}

/// An inline, tappable acronym that shows an accessible tooltip card.
///
/// When activated (tap/Enter/Space) or focused/hovered (if enabled), this
/// widget opens a Material overlay positioned near the inline text. The overlay
/// renders a small card (see [DashronymTooltipCard]) with the acronym and its
/// full [description]. It supports keyboard, screen reader, and pointer
/// interactions:
///
/// * Tap/click or activate (Enter/Space) to toggle the tooltip.
/// * Press Escape to dismiss.
/// * Hover show/hide is supported when [DashronymTheme.enableHover] is `true`.
/// * Screen readers receive a live-region update or a supported platform
///   announcement, without both paths firing for the same state change.
///
/// The trigger text inherits [textStyle] and can be customized by
/// [DashronymTheme] (e.g., underline, thickness, fade durations, offsets).
///
/// Typical usage inside a `WidgetSpan`:
/// ```dart
/// Text.rich(
///   TextSpan(
///     children: [
///       WidgetSpan(
///         alignment: PlaceholderAlignment.baseline,
///         baseline: TextBaseline.alphabetic,
///         child: DashronymInline(
///           acronym: 'SDK',
///           description: 'Software Development Kit',
///           theme: myDashronymTheme,
///           textStyle: Theme.of(context).textTheme.bodyMedium,
///         ),
///       ),
///     ],
///   ),
/// );
/// ```
///
/// Semantics:
/// This widget exposes a button role, expanded/collapsed state, and a dynamic
/// show/hide hint. Platforms that support explicit announcements receive a
/// polite view-scoped event; other platforms discover the inserted tooltip as
/// a live region.
///
/// Layout/overlay:
/// Uses [OverlayPortal.overlayChildLayoutBuilder] to position the tooltip from
/// the trigger's layout transform. The portal preserves trigger-local inherited
/// widgets, supports nested overlays, and owns the tooltip lifecycle so the
/// surface cannot outlive its inline trigger.
class DashronymInline extends StatefulWidget {
  /// Creates an inline acronym control that shows a tooltip when activated.
  const DashronymInline({
    super.key,
    required this.acronym,
    required this.description,
    required this.theme,
    required this.textStyle,
    this.tooltipBuilder,
    this.textScaler,
    this.locale,
    this.spellOut,
    this.semanticsIdentifier,
  });

  /// The acronym text shown inline (e.g., `"SDK"`).
  final String acronym;

  /// The descriptive text rendered inside the tooltip card.
  final String description;

  /// Visual and interaction parameters for the trigger and tooltip.
  ///
  /// See [DashronymTheme] for underline, decoration, timing, and offset options.
  final DashronymTheme theme;

  /// Base text style inherited from the surrounding span.
  ///
  /// The trigger style is derived from this plus any overrides in [theme].
  final TextStyle? textStyle;

  /// Allows callers to provide a custom tooltip instead of [DashronymTooltipCard].
  final DashronymTooltipBuilder? tooltipBuilder;

  /// Overrides scaling for the inline trigger text.
  ///
  /// This is primarily used by Dashronym's [WidgetSpan] adapter, because
  /// Flutter scales inline widgets automatically. Direct [DashronymInline]
  /// instances should normally leave this `null` to honor the ambient
  /// [MediaQuery] text scaler.
  @internal
  final TextScaler? textScaler;

  /// Locale inherited from the authored source span, when present.
  @internal
  final Locale? locale;

  /// Whether assistive technology should spell the acronym character by
  /// character.
  @internal
  final bool? spellOut;

  /// Stable semantics identifier inherited from the authored source span.
  @internal
  final String? semanticsIdentifier;

  /// Creates the backing state object.
  ///
  /// You typically do not need to call this.
  @override
  State<DashronymInline> createState() => _DashronymInlineState();
}

class _DashronymInlineState extends State<DashronymInline>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final OverlayPortalController _portalController = OverlayPortalController(
    debugLabel: 'DashronymTooltip',
  );

  bool _tooltipVisible = false;
  bool _showFocusHighlight = false;
  Timer? _announceDebounce;
  ScrollPosition? _scrollPosition;
  DashronymTooltipController? _tooltipController;
  late final DashronymTooltipInteraction _interaction;
  late final AnimationController _fadeController;
  late CurvedAnimation _opacity;
  late CurvedAnimation _scaleCurve;
  late Animation<double> _scale;
  late final Map<Type, Action<Intent>> _activateActions = {
    ActivateIntent: _TriggerActivateAction<ActivateIntent>(this),
    // The web maps Enter to ButtonActivateIntent rather than ActivateIntent,
    // so handle both, as Flutter's own buttons do.
    ButtonActivateIntent: _TriggerActivateAction<ButtonActivateIntent>(this),
  };
  late final OnKeyEventCallback _earlyEscapeHandler = _handleEarlyEscape;
  late final KeyEventCallback _unfocusedEscapeHandler = _handleUnfocusedEscape;
  bool _keyboardHandlerRegistered = false;
  bool _isDisposing = false;
  int _visibilityGeneration = 0;
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _interaction = DashronymTooltipInteraction(
      showTooltip: _show,
      hideTooltip: _hide,
      isAlive: () => mounted && !_isDisposing,
      hoverShowDelay: widget.theme.hoverShowDelay,
      hoverHideDelay:
          widget.theme.hoverHideDelay ?? widget.theme.hoverShowDelay,
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: widget.theme.tooltipFadeDuration,
      value: 0,
      debugLabel: 'DashronymTooltip',
    );
    _configureAnimations(widget.theme);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposing) return;
      _attachScrollListener();
    });
  }

  @override
  void dispose() {
    _isDisposing = true;
    _visibilityGeneration++;
    _announceDebounce?.cancel();
    _scrollPosition?.removeListener(_handleScrollDismiss);
    _scrollPosition = null;
    _hide(immediate: true, announce: false);
    _tooltipController?.release(this);
    _tooltipController = null;
    _unregisterKeyboardHandler();
    _interaction.dispose();
    _disposeAnimations();
    _fadeController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @visibleForTesting
  void debugRemoveEntry() {
    _visibilityGeneration++;
    _unregisterKeyboardHandler();
    _portalController.hide();
    _tooltipVisible = false;
    _tooltipController?.release(this);
  }

  @override
  void didUpdateWidget(covariant DashronymInline oldWidget) {
    super.didUpdateWidget(oldWidget);
    _interaction.updateHoverDelays(
      showDelay: widget.theme.hoverShowDelay,
      hideDelay: widget.theme.hoverHideDelay ?? widget.theme.hoverShowDelay,
    );
    if (oldWidget.theme.tooltipFadeDuration !=
        widget.theme.tooltipFadeDuration) {
      _fadeController.duration = widget.theme.tooltipFadeDuration;
    }
    if (_animationSettingsChanged(oldWidget.theme, widget.theme)) {
      _disposeAnimations();
      _configureAnimations(widget.theme);
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final orientation = _windowOrientation();
    if (_tooltipVisible) {
      _hide(immediate: true);
    }
    if (orientation != null) {
      _lastOrientation = orientation;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextTooltipController = DashronymTooltipScope.maybeControllerOf(
      context,
    );
    if (!identical(_tooltipController, nextTooltipController)) {
      if (_tooltipVisible || _portalController.isShowing) {
        _hide(immediate: true, announce: false);
      }
      _tooltipController?.release(this);
      _tooltipController = nextTooltipController;
    }
    final orientation = MediaQuery.maybeOf(context)?.orientation;
    if (orientation != null && _lastOrientation != orientation) {
      if (_lastOrientation != null) {
        _hide(immediate: true); // coverage:ignore-line
      }
      _lastOrientation = orientation;
    }
    _attachScrollListener();
  }

  Orientation? _windowOrientation() {
    final view = View.maybeOf(context);
    if (view == null) return null;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    if (logicalSize.width == 0 || logicalSize.height == 0) return null;
    return logicalSize.width > logicalSize.height
        ? Orientation.landscape
        : Orientation.portrait;
  }

  void _attachScrollListener() {
    if (_isDisposing) return;
    final scrollableState = Scrollable.maybeOf(context);
    final newPosition = scrollableState?.position;
    if (identical(_scrollPosition, newPosition)) return;
    _scrollPosition?.removeListener(_handleScrollDismiss);
    _scrollPosition = newPosition;
    _scrollPosition?.addListener(_handleScrollDismiss);
  }

  void _handleScrollDismiss() {
    if (!_tooltipVisible || _isDisposing) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposing) return;
      _hide();
    });
  }

  void _configureAnimations(DashronymTheme theme) {
    _opacity = CurvedAnimation(
      parent: _fadeController,
      curve: theme.tooltipFadeInCurve,
      reverseCurve: theme.tooltipFadeOutCurve,
    );
    _scaleCurve = CurvedAnimation(
      parent: _fadeController,
      curve: theme.tooltipScaleInCurve,
      reverseCurve: theme.tooltipScaleOutCurve,
    );
    _scale = Tween<double>(
      begin: theme.tooltipScaleBegin,
      end: theme.tooltipScaleEnd,
    ).animate(_scaleCurve);
  }

  void _disposeAnimations() {
    _opacity.dispose();
    _scaleCurve.dispose();
  }

  bool _animationSettingsChanged(
    DashronymTheme previous,
    DashronymTheme next,
  ) {
    return previous.tooltipFadeInCurve != next.tooltipFadeInCurve ||
        previous.tooltipFadeOutCurve != next.tooltipFadeOutCurve ||
        previous.tooltipScaleInCurve != next.tooltipScaleInCurve ||
        previous.tooltipScaleOutCurve != next.tooltipScaleOutCurve ||
        previous.tooltipScaleBegin != next.tooltipScaleBegin ||
        previous.tooltipScaleEnd != next.tooltipScaleEnd;
  }

  bool _dismissesOnEscape(KeyEvent event) {
    return (event is KeyDownEvent || event is KeyRepeatEvent) &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _tooltipVisible &&
        mounted &&
        // Leave Escape to a newer route, such as a dialog or menu, that now
        // covers the trigger while its tooltip is still on its way out.
        (ModalRoute.isCurrentOf(context) ?? true);
  }

  /// Dismisses a visible tooltip before the focus tree sees Escape.
  ///
  /// Early handlers run ahead of [Shortcuts], so handling the key here keeps
  /// the same press from also dismissing an enclosing dialog or route.
  KeyEventResult _handleEarlyEscape(KeyEvent event) {
    if (!_dismissesOnEscape(event)) return KeyEventResult.ignored;
    // Close the topmost layer first: a tooltip shown for a control inside the
    // card, such as the close button's label, goes before the card itself.
    if (RawTooltip.dismissAllToolTips()) return KeyEventResult.handled;
    _hide(restoreFocus: _interaction.tooltipFocusScope.hasFocus);
    return KeyEventResult.handled;
  }

  /// Dismisses a visible tooltip when nothing has keyboard focus.
  ///
  /// The focus manager ignores key events without a primary focus, so its
  /// early handlers never run in that state.
  bool _handleUnfocusedEscape(KeyEvent event) {
    if (FocusManager.instance.primaryFocus != null ||
        !_dismissesOnEscape(event)) {
      return false;
    }
    _hide();
    return true;
  }

  void _registerKeyboardHandler() {
    if (_keyboardHandlerRegistered) return;
    FocusManager.instance.addEarlyKeyEventHandler(_earlyEscapeHandler);
    HardwareKeyboard.instance.addHandler(_unfocusedEscapeHandler);
    _keyboardHandlerRegistered = true;
  }

  void _unregisterKeyboardHandler() {
    if (!_keyboardHandlerRegistered) return;
    FocusManager.instance.removeEarlyKeyEventHandler(_earlyEscapeHandler);
    HardwareKeyboard.instance.removeHandler(_unfocusedEscapeHandler);
    _keyboardHandlerRegistered = false;
  }

  void _announce(String message) {
    if (_isDisposing || !MediaQuery.supportsAnnounceOf(context)) return;
    _announceDebounce?.cancel();
    _announceDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted || _isDisposing || !MediaQuery.supportsAnnounceOf(context)) {
        return;
      }
      final view = View.of(context);
      unawaited(
        SemanticsService.sendAnnouncement(
          view,
          message,
          Directionality.of(context),
        ).catchError((Object error, StackTrace stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'dashronym',
              context: ErrorDescription(
                'while announcing an acronym tooltip',
              ),
            ),
          );
        }),
      );
    });
  }

  void _toggle() {
    if (_tooltipVisible) {
      _hide();
    } else {
      _show();
    }
  }

  void _show() {
    if (_tooltipVisible || _isDisposing) return;
    _interaction.cancelPending();

    final strings = DashronymLocalizations.of(context);

    _tooltipController?.activate(
      this,
      () => _hide(immediate: true, announce: false),
    );
    _visibilityGeneration++;
    setState(() {
      _tooltipVisible = true;
    });
    _registerKeyboardHandler();
    _portalController.show();
    _fadeController.forward();

    _announce(
      strings.announceTooltipContent(
        widget.acronym,
        widget.description,
      ),
    );
  }

  void _hide({
    bool immediate = false,
    bool announce = true,
    bool restoreFocus = false,
  }) {
    _interaction.cancelPending();
    _announceDebounce?.cancel();
    _unregisterKeyboardHandler();
    if (!_tooltipVisible && !_portalController.isShowing) {
      if (restoreFocus) {
        _interaction.restoreTriggerFocus();
      }
      return;
    }

    final generation = ++_visibilityGeneration;
    final wasVisible = _tooltipVisible;

    void completeRemoval() {
      if (generation != _visibilityGeneration || _tooltipVisible) {
        return;
      }
      if (_portalController.isShowing) {
        _portalController.hide();
      }
      _tooltipController?.release(this);
      if (!mounted || _isDisposing) {
        return;
      }
      if (announce && wasVisible) {
        final strings = DashronymLocalizations.of(context);
        _announce(strings.announceTooltipHidden(widget.acronym));
      }
      if (restoreFocus) {
        _interaction.restoreTriggerFocus();
      }
    }

    if (mounted && !_isDisposing && wasVisible) {
      setState(() {
        _tooltipVisible = false;
      });
    } else {
      _tooltipVisible = false;
    }
    if (immediate) {
      _fadeController.stop();
      _fadeController.value = 0;
      completeRemoval();
      return;
    }

    _fadeController.reverse().whenComplete(completeRemoval);
  }

  Widget _buildTooltip(BuildContext context) {
    final tooltipDetails = DashronymTooltipDetails(
      acronym: widget.acronym,
      description: widget.description,
      theme: widget.theme,
      hideTooltip: () => _hide(restoreFocus: true),
    );
    return widget.tooltipBuilder?.call(context, tooltipDetails) ??
        DashronymTooltipCard(
          acronym: widget.acronym,
          description: widget.description,
          theme: widget.theme,
          onClose: () => _hide(restoreFocus: true),
          textColorHint: widget.textStyle?.color,
        );
  }

  TextStyle _effectiveTextStyle(BuildContext context) {
    final base = widget.textStyle ?? DefaultTextStyle.of(context).style;
    var style = base.copyWith(
      decoration: widget.theme.underline
          ? TextDecoration.underline
          : TextDecoration.none,
      decorationStyle: widget.theme.decorationStyle,
      decorationThickness: widget.theme.decorationThickness,
      fontWeight: base.fontWeight ?? FontWeight.w600,
    );
    if (widget.theme.acronymStyle case final acronymStyle?) {
      style = style.merge(acronymStyle);
    }
    if (_showFocusHighlight) {
      style = style.copyWith(
        backgroundColor: DashronymCardPalette.focusHighlight(
          context,
          widget.theme,
          style.color,
        ),
      );
    }
    return style;
  }

  @override
  Widget build(BuildContext context) {
    final strings = DashronymLocalizations.of(context);
    final textWidget = Text(
      widget.acronym,
      style: _effectiveTextStyle(context),
      textScaler: widget.textScaler,
      locale: widget.locale,
    );

    Widget result = GestureDetector(
      onTap: () => _interaction.handleTriggerTap(wasVisible: _tooltipVisible),
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        onEnter: widget.theme.enableHover
            ? (_) => _interaction.handleTriggerEnter()
            : null,
        onExit: widget.theme.enableHover
            ? (_) => _interaction.handleTriggerExit()
            : null,
        cursor: SystemMouseCursors.click,
        child: textWidget,
      ),
    );

    result = DashronymTooltipOverlay(
      controller: _portalController,
      theme: widget.theme,
      opacity: _opacity,
      scale: _scale,
      tooltipFocusScope: _interaction.tooltipFocusScope,
      tooltipBuilder: _buildTooltip,
      makeScrollable: widget.tooltipBuilder != null,
      onDismiss: () => _hide(restoreFocus: true),
      onOutsideDismiss: () {
        _hide();
        _interaction.triggerFocusNode.unfocus();
      },
      onTooltipEnter: _interaction.handleTooltipEnter,
      onTooltipExit: _interaction.handleTooltipExit,
      onTooltipFocusChange: _interaction.handleTooltipFocusChange,
      child: result,
    );

    result = FocusableActionDetector(
      focusNode: _interaction.triggerFocusNode,
      onFocusChange: _interaction.handleTriggerFocusChange,
      onShowFocusHighlight: (show) {
        if (show == _showFocusHighlight || !mounted) return;
        setState(() {
          _showFocusHighlight = show;
        });
      },
      actions: <Type, Action<Intent>>{
        ..._activateActions,
        // Escape itself is handled by the early key handler while a tooltip
        // is visible; this action serves DismissIntent from other shortcuts.
        // Claim it only while there is a tooltip to dismiss, so the intent
        // otherwise reaches enclosing routes, such as a dialog.
        if (_tooltipVisible)
          DismissIntent: CallbackAction<Intent>(
            onInvoke: (_) {
              _hide(restoreFocus: true);
              return null;
            },
          ),
      },
      child: result,
    );

    final attributeRange = TextRange(
      start: 0,
      end: widget.acronym.length,
    );
    final labelAttributes = <StringAttribute>[
      if (widget.spellOut ?? false)
        SpellOutStringAttribute(range: attributeRange),
      if (widget.locale case final locale?)
        LocaleStringAttribute(locale: locale, range: attributeRange),
    ];
    final attributedLabel = labelAttributes.isEmpty
        ? null
        : AttributedString(widget.acronym, attributes: labelAttributes);

    return Semantics(
      // Flutter 3.38 requires nodes that assign a locale to their subtree to
      // establish a semantics container. Keep this conditional so triggers
      // without authored locale metadata preserve their existing tree shape.
      container: widget.locale != null,
      button: true,
      expanded: _tooltipVisible,
      label: attributedLabel == null ? widget.acronym : null,
      attributedLabel: attributedLabel,
      identifier: widget.semanticsIdentifier,
      localeForSubtree: widget.locale,
      hint: _tooltipVisible
          ? strings.semanticsHintHide(widget.acronym)
          : strings.semanticsHintShow(widget.acronym),
      onTap: _toggle,
      child: result,
    );
  }
}

/// Toggles a trigger's tooltip from an activation intent, but only while the
/// trigger itself has primary focus.
///
/// Tooltip content is built in the trigger's context and inherits its actions.
/// Without this guard, an activation intent from a focusable inside a custom
/// tooltip would bubble up and close the tooltip under the user's focus.
class _TriggerActivateAction<T extends Intent> extends Action<T> {
  _TriggerActivateAction(this._state);

  final _DashronymInlineState _state;

  @override
  bool isEnabled(T intent) =>
      _state._interaction.triggerFocusNode.hasPrimaryFocus;

  @override
  Object? invoke(T intent) {
    _state._toggle();
    return null;
  }
}
