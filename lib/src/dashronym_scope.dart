import 'package:flutter/widgets.dart';

import 'acronym_inline.dart';
import 'config.dart';
import 'dashronym_theme.dart';
import 'registry.dart';

/// Provides shared Dashronym defaults to a widget subtree.
///
/// Use a scope near the top of an app or feature when several text widgets use
/// the same glossary:
///
/// ```dart
/// DashronymScope(
///   registry: AcronymRegistry({
///     'API': 'Application Programming Interface',
///   }),
///   config: const DashronymConfig(enableBareAcronyms: true),
///   child: const Article(),
/// )
/// ```
///
/// Descendant `DashronymText` widgets and `Text.dashronyms()` calls can omit
/// values supplied by this scope. Explicit widget arguments take precedence.
class DashronymScope extends InheritedWidget {
  /// Creates a scope containing shared glossary defaults.
  const DashronymScope({
    super.key,
    required this.registry,
    this.config = const DashronymConfig(),
    this.theme,
    this.tooltipBuilder,
    required super.child,
  });

  /// Acronym definitions available to descendants.
  final AcronymRegistry registry;

  /// Default parser configuration for descendants.
  final DashronymConfig config;

  /// Optional visual defaults for descendants.
  ///
  /// When omitted, descendants can use a `DashronymTheme` installed in
  /// `ThemeData.extensions`, followed by the package defaults.
  final DashronymTheme? theme;

  /// Optional custom tooltip builder shared by descendants.
  final DashronymTooltipBuilder? tooltipBuilder;

  /// Returns the nearest scope, or `null` when no scope is installed.
  static DashronymScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DashronymScope>();
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
        'Wrap this subtree in DashronymScope, or pass an AcronymRegistry '
        'directly to the Dashronym widget.',
      ),
    ]);
  }

  @override
  bool updateShouldNotify(DashronymScope oldWidget) {
    return registry != oldWidget.registry ||
        config != oldWidget.config ||
        theme != oldWidget.theme ||
        tooltipBuilder != oldWidget.tooltipBuilder;
  }
}
