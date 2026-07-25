import 'package:flutter/widgets.dart';

import 'dashronym_inline.dart';
import 'dashronym_config.dart';
import 'dashronym_theme.dart';
import 'dashronym_registry.dart';
import 'dashronym_tooltip_controller.dart';

/// Provides shared Dashronym defaults to a widget subtree.
///
/// Use a scope near the top of an app or feature when several text widgets use
/// the same definitions:
///
/// ```dart
/// DashronymScope(
///   registry: DashronymRegistry({
///     'API': 'Application Programming Interface',
///   }),
///   child: const Article(),
/// )
/// ```
///
/// Descendant `DashronymText` widgets and `Text.dashronyms()` calls can omit
/// values supplied by this scope. Explicit widget arguments take precedence.
class DashronymScope extends StatefulWidget {
  /// Creates a scope containing shared Dashronym defaults.
  const DashronymScope({
    super.key,
    required this.registry,
    this.config = const DashronymConfig(),
    this.theme,
    this.tooltipBuilder,
    required this.child,
  });

  /// Acronym definitions available to descendants.
  final DashronymRegistry registry;

  /// Default parser configuration for descendants.
  final DashronymConfig config;

  /// Optional visual defaults for descendants.
  ///
  /// When omitted, descendants can use a `DashronymTheme` installed in
  /// `ThemeData.extensions`, followed by the package defaults.
  final DashronymTheme? theme;

  /// Optional custom tooltip builder shared by descendants.
  final DashronymTooltipBuilder? tooltipBuilder;

  /// The subtree receiving shared defaults and tooltip coordination.
  final Widget child;

  /// Returns the nearest scope, or `null` when no scope is installed.
  static DashronymScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_DashronymScopeProvider>()
        ?.scope;
  }

  /// Returns the nearest scope.
  ///
  /// Throws a descriptive [FlutterError] when no scope is installed.
  static DashronymScope of(BuildContext context) {
    final scope = maybeOf(context);
    if (scope != null) return scope;

    throw FlutterError.fromParts([
      ErrorSummary('No DashronymScope found.'),
      ErrorDescription(
        'DashronymScope.of() was called with a context that does not contain '
        'a DashronymScope.',
      ),
      ErrorHint(
        'Wrap this subtree in DashronymScope, or pass a DashronymRegistry '
        'directly to the Dashronym widget.',
      ),
    ]);
  }

  bool _shouldNotify(DashronymScope oldWidget) {
    return registry != oldWidget.registry ||
        config != oldWidget.config ||
        theme != oldWidget.theme ||
        tooltipBuilder != oldWidget.tooltipBuilder;
  }

  @override
  State<DashronymScope> createState() => _DashronymScopeState();
}

class _DashronymScopeState extends State<DashronymScope> {
  @override
  Widget build(BuildContext context) {
    return _DashronymScopeProvider(
      scope: widget,
      child: DashronymTooltipScope(child: widget.child),
    );
  }
}

class _DashronymScopeProvider extends InheritedWidget {
  const _DashronymScopeProvider({
    required this.scope,
    required super.child,
  });

  final DashronymScope scope;

  @override
  bool updateShouldNotify(_DashronymScopeProvider oldWidget) =>
      scope._shouldNotify(oldWidget.scope);
}
