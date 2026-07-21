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
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'dashronym_entry.dart';
import 'dashronym_localizations.dart';
import 'dashronym_theme.dart';
import 'dashronym_tooltip_card.dart';
import 'dashronym_tooltip_positioner.dart';
import 'dashronym_tooltip_constraints.dart';

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
typedef DashronymTooltipBuilder =
    Widget Function(BuildContext context, DashronymTooltipDetails details);

/// Data surfaced to [DashronymTooltipBuilder] implementations.
class DashronymTooltipDetails {
  /// Creates tooltip metadata provided to custom tooltip builders.
  const DashronymTooltipDetails({
    required this.acronym,
    required this.description,
    required this.theme,
    required this.hideTooltip,
    this.entry,
  });

  /// The acronym shown by the inline trigger.
  final String acronym;

  /// The long-form description associated with [acronym].
  final String description;

  /// The effective theme driving tooltip styling.
  final DashronymTheme theme;

  /// Callback that hides the tooltip overlay.
  final VoidCallback hideTooltip;

  /// Rich glossary metadata for [acronym], when available.
  ///
  /// Legacy registries with values that cannot form a valid [DashronymEntry]
  /// leave this `null`.
  final DashronymEntry? entry;
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
    this.entry,
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

  /// Rich glossary metadata associated with [acronym], when available.
  @internal
  final DashronymEntry? entry;

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
  static _DashronymInlineState? _activeTooltip;

  final FocusNode _focusNode = FocusNode(debugLabel: 'DashronymInline');
  final FocusScopeNode _tooltipFocusScope = FocusScopeNode(
    debugLabel: 'DashronymTooltip',
  );
  final OverlayPortalController _portalController = OverlayPortalController(
    debugLabel: 'DashronymTooltip',
  );

  bool _hoveringTrigger = false;
  bool _hoveringTooltip = false;
  bool _tooltipVisible = false;
  bool _showFocusHighlight = false;
  bool _suppressFocusShow = false;
  Timer? _hoverShowTimer;
  Timer? _hoverHideTimer;
  Timer? _announceDebounce;
  ScrollPosition? _scrollPosition;
  late Duration _hoverHideDelay;
  late final AnimationController _fadeController;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  bool _isDisposing = false;
  int _visibilityGeneration = 0;
  Orientation? _lastOrientation;

  static const double _viewportMargin = 8.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hoverHideDelay =
        widget.theme.hoverHideDelay ?? widget.theme.hoverShowDelay;
    _fadeController = AnimationController(
      vsync: this,
      duration: widget.theme.tooltipFadeDuration,
      value: 0,
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
    _hoverShowTimer?.cancel();
    _hoverHideTimer?.cancel();
    _announceDebounce?.cancel();
    _scrollPosition?.removeListener(_handleScrollDismiss);
    _scrollPosition = null;
    _hide(immediate: true, announce: false);
    if (identical(_activeTooltip, this)) {
      _activeTooltip = null;
    }
    _focusNode.dispose();
    _tooltipFocusScope.dispose();
    _fadeController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @visibleForTesting
  void debugRemoveEntry() {
    _visibilityGeneration++;
    _portalController.hide();
    _tooltipVisible = false;
  }

  @override
  void didUpdateWidget(covariant DashronymInline oldWidget) {
    super.didUpdateWidget(oldWidget);
    _hoverHideDelay =
        widget.theme.hoverHideDelay ?? widget.theme.hoverShowDelay;
    if (oldWidget.theme.tooltipFadeDuration !=
        widget.theme.tooltipFadeDuration) {
      _fadeController.duration = widget.theme.tooltipFadeDuration;
    }
    _configureAnimations(widget.theme);
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
    _scale =
        Tween<double>(
          begin: theme.tooltipScaleBegin,
          end: theme.tooltipScaleEnd,
        ).animate(
          CurvedAnimation(
            parent: _fadeController,
            curve: theme.tooltipScaleInCurve,
            reverseCurve: theme.tooltipScaleOutCurve,
          ),
        );
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
    _hoverShowTimer?.cancel();
    _hoverHideTimer?.cancel();

    final strings = DashronymLocalizations.of(context);

    if (_activeTooltip != this) {
      _activeTooltip?._hide(immediate: true, announce: false);
    }
    _activeTooltip = this;
    _visibilityGeneration++;
    setState(() {
      _tooltipVisible = true;
    });
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
    _hoverShowTimer?.cancel();
    _hoverHideTimer?.cancel();
    _announceDebounce?.cancel();
    if (!_tooltipVisible && !_portalController.isShowing) {
      if (restoreFocus) {
        _restoreTriggerFocus();
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
      if (identical(_activeTooltip, this)) {
        _activeTooltip = null;
      }
      if (!mounted || _isDisposing) {
        _hoveringTrigger = false;
        _hoveringTooltip = false;
        return;
      }
      if (announce && wasVisible) {
        final strings = DashronymLocalizations.of(context);
        _announce(strings.announceTooltipHidden(widget.acronym));
      }
      if (restoreFocus) {
        _restoreTriggerFocus();
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

  void _restoreTriggerFocus() {
    if (!mounted || _isDisposing || !_focusNode.canRequestFocus) return;
    _suppressFocusShow = true;
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _suppressFocusShow = false;
    });
  }

  void _scheduleHoverHide() {
    _hoverHideTimer?.cancel();
    _hoverHideTimer = Timer(_hoverHideDelay, () {
      if (!mounted ||
          _isDisposing ||
          _hoveringTrigger ||
          _hoveringTooltip ||
          _focusNode.hasFocus ||
          _tooltipFocusScope.hasFocus) {
        return;
      }
      _hide();
    });
  }

  void _handleFocusLoss() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _isDisposing ||
          _focusNode.hasFocus ||
          _tooltipFocusScope.hasFocus ||
          _hoveringTrigger ||
          _hoveringTooltip) {
        return;
      }
      _hide();
    });
  }

  Widget _buildOverlay(
    BuildContext context,
    OverlayChildLayoutInfo layoutInfo,
  ) {
    final triggerMediaQuery = MediaQuery.maybeOf(this.context);
    final anchorRect = MatrixUtils.transformRect(
      layoutInfo.childPaintTransform,
      Offset.zero & layoutInfo.childSize,
    );
    final tooltipDetails = DashronymTooltipDetails(
      acronym: widget.acronym,
      description: widget.description,
      theme: widget.theme,
      hideTooltip: () => _hide(restoreFocus: true),
      entry: widget.entry,
    );
    final isCustomTooltip = widget.tooltipBuilder != null;
    final builtTooltip =
        widget.tooltipBuilder?.call(context, tooltipDetails) ??
        DashronymTooltipCard(
          acronym: widget.acronym,
          description: widget.description,
          theme: widget.theme,
          onClose: () => _hide(restoreFocus: true),
        );
    final tooltip = _TooltipViewportClamp(
      theme: widget.theme,
      mediaQuery: triggerMediaQuery,
      makeScrollable: isCustomTooltip,
      child: builtTooltip,
    );

    Widget result = Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _hide(restoreFocus: true);
              return null;
            },
          ),
        },
        child: FocusScope(
          node: _tooltipFocusScope,
          onFocusChange: (focused) {
            if (focused) {
              _hoverHideTimer?.cancel();
            } else {
              _handleFocusLoss();
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      _hide();
                      _focusNode.unfocus();
                    },
                    onSecondaryTap: () {
                      _hide();
                      _focusNode.unfocus();
                    },
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomSingleChildLayout(
                  delegate: _DashronymTooltipLayoutDelegate(
                    anchorRect: anchorRect,
                    theme: widget.theme,
                    padding: triggerMediaQuery?.padding ?? EdgeInsets.zero,
                    keyboardInset: triggerMediaQuery?.viewInsets.bottom ?? 0.0,
                    direction: Directionality.of(this.context),
                    viewportMargin: _viewportMargin,
                  ),
                  child: MouseRegion(
                    opaque: false,
                    onEnter: widget.theme.enableHover
                        ? (_) {
                            _hoveringTooltip = true;
                            _hoverHideTimer?.cancel();
                          }
                        : null,
                    onExit: widget.theme.enableHover
                        ? (_) {
                            _hoveringTooltip = false;
                            _scheduleHoverHide();
                          }
                        : null,
                    child: FadeTransition(
                      opacity: _opacity,
                      child: ScaleTransition(
                        scale: _scale,
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
    if (triggerMediaQuery != null) {
      result = MediaQuery(data: triggerMediaQuery, child: result);
    }
    // The layout-builder portal provides root-overlay constraints even when the
    // source lives in a tightly constrained WidgetSpan.
    return Positioned.fill(child: result);
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
        backgroundColor: Theme.of(context).focusColor,
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
      onTap: () {
        final wasVisible = _tooltipVisible;
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
        if (wasVisible) {
          _hide();
        } else {
          _show();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        onEnter: widget.theme.enableHover
            ? (_) {
                _hoveringTrigger = true;
                _hoverShowTimer?.cancel();
                _hoverHideTimer?.cancel();
                _hoverShowTimer = Timer(widget.theme.hoverShowDelay, () {
                  if (mounted && !_isDisposing && _hoveringTrigger) {
                    _show();
                  }
                });
              }
            : null,
        onExit: widget.theme.enableHover
            ? (_) {
                _hoveringTrigger = false;
                _hoverShowTimer?.cancel();
                _scheduleHoverHide();
              }
            : null,
        cursor: SystemMouseCursors.click,
        child: textWidget,
      ),
    );

    result = OverlayPortal.overlayChildLayoutBuilder(
      controller: _portalController,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: _buildOverlay,
      child: result,
    );

    result = FocusableActionDetector(
      focusNode: _focusNode,
      onFocusChange: (focused) {
        if (focused) {
          _hoverHideTimer?.cancel();
          if (!_suppressFocusShow) {
            _show();
          }
        } else {
          _handleFocusLoss();
        }
      },
      onShowFocusHighlight: (show) {
        if (show == _showFocusHighlight || !mounted) return;
        setState(() {
          _showFocusHighlight = show;
        });
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<Intent>(
          onInvoke: (_) {
            _toggle();
            return null;
          },
        ),
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

class _DashronymTooltipLayoutDelegate extends SingleChildLayoutDelegate {
  const _DashronymTooltipLayoutDelegate({
    required this.anchorRect,
    required this.theme,
    required this.padding,
    required this.keyboardInset,
    required this.direction,
    required this.viewportMargin,
  });

  final Rect anchorRect;
  final DashronymTheme theme;
  final EdgeInsets padding;
  final double keyboardInset;
  final TextDirection direction;
  final double viewportMargin;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final relativeOffset = DashronymTooltipPositioner.resolveOffset(
      overlaySize: size,
      anchorTopLeft: anchorRect.topLeft,
      anchorSize: anchorRect.size,
      tooltipSize: childSize,
      theme: theme,
      padding: padding,
      keyboardInset: keyboardInset,
      direction: direction,
      viewportMargin: viewportMargin,
    );
    return anchorRect.topLeft + relativeOffset;
  }

  @override
  bool shouldRelayout(_DashronymTooltipLayoutDelegate oldDelegate) =>
      anchorRect != oldDelegate.anchorRect ||
      theme != oldDelegate.theme ||
      padding != oldDelegate.padding ||
      keyboardInset != oldDelegate.keyboardInset ||
      direction != oldDelegate.direction ||
      viewportMargin != oldDelegate.viewportMargin;
}

class _TooltipViewportClamp extends StatelessWidget {
  const _TooltipViewportClamp({
    required this.theme,
    required this.mediaQuery,
    required this.makeScrollable,
    required this.child,
  });

  final DashronymTheme theme;
  final MediaQueryData? mediaQuery;
  final bool makeScrollable;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, parentConstraints) {
        final mqForBuilder = mediaQuery ?? MediaQuery.maybeOf(context);
        final resolvedConstraints = DashronymTooltipConstraints.resolve(
          constraints: parentConstraints,
          mediaQuery: mqForBuilder,
          theme: theme,
        );
        final appliedConstraints = makeScrollable
            ? resolvedConstraints.copyWith(
                minWidth: (theme.tooltipMaxWidth ?? theme.cardWidth)
                    .clamp(
                      resolvedConstraints.minWidth,
                      resolvedConstraints.maxWidth,
                    )
                    .toDouble(),
              )
            : resolvedConstraints;
        final constrainedChild = makeScrollable
            ? SingleChildScrollView(primary: false, child: child)
            : child;
        return DashronymTooltipConstraintScope(
          constraints: appliedConstraints,
          child: ConstrainedBox(
            constraints: appliedConstraints,
            // Material elevation is paint overflow and must remain visible
            // outside the card's layout bounds. The stock card and custom
            // scroll host already clip their own overflowing contents.
            child: constrainedChild,
          ),
        );
      },
    );
  }
}
