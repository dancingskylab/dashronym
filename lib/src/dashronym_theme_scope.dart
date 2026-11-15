/// @docImport 'dashronym_scope.dart';
library;

import 'package:flutter/widgets.dart';

import 'dashronym_theme.dart';

/// Provides a [DashronymTheme] to every Dashronym widget in a subtree.
///
/// Install one near the root of an app to theme all acronyms, for example in
/// the `builder` of `MaterialApp`, `CupertinoApp` or `WidgetsApp`, so that it
/// sits above the navigator and applies to every route:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => DashronymThemeScope(
///     data: const DashronymTheme(cardElevation: 2, tooltipMaxWidth: 360),
///     child: child!,
///   ),
///   home: const Article(),
/// )
/// ```
///
/// Unlike a theme extension, which is tied to one Material library, this
/// scope reaches Dashronym widgets in any app, including apps built on the
/// standalone `material_ui` package. It is an [InheritedTheme], so routes that
/// capture themes (such as dialogs and menus) carry it into their overlays.
///
/// Dashronym resolves its theme from, in order: a `theme` passed to the
/// widget, [DashronymScope.theme], the nearest [DashronymThemeScope], a
/// [DashronymTheme] installed in `ThemeData.extensions`, and finally the
/// package defaults. A theme set on a [DashronymScope] therefore takes
/// precedence over a [DashronymThemeScope] placed inside it; to restyle part
/// of such a subtree, pass the theme to its widgets or to a nested
/// [DashronymScope]. Dashronym 0.3.0 removes the `ThemeData.extensions` step,
/// so prefer this scope for app-wide theming.
///
/// In 0.2.x the stock tooltip card still takes its surface color, and any
/// icon color or text styles that this theme leaves unset, from the
/// `package:flutter/material.dart` `Theme`. Apps on the standalone
/// `material_ui` package can set [DashronymTheme.cardIconColor],
/// [DashronymTheme.cardTitleStyle] and [DashronymTheme.cardSubtitleStyle]
/// explicitly, or supply a custom tooltip builder.
class DashronymThemeScope extends InheritedTheme {
  /// Creates a scope that provides [data] to [child].
  const DashronymThemeScope({
    super.key,
    required this.data,
    required super.child,
  });

  /// The theme provided to descendants.
  final DashronymTheme data;

  /// Returns the theme from the nearest [DashronymThemeScope], or `null` when
  /// there is none.
  static DashronymTheme? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DashronymThemeScope>()
        ?.data;
  }

  /// Returns the theme from the nearest [DashronymThemeScope], or the package
  /// defaults when there is none.
  static DashronymTheme of(BuildContext context) {
    return maybeOf(context) ?? const DashronymTheme();
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return DashronymThemeScope(data: data, child: child);
  }

  @override
  bool updateShouldNotify(DashronymThemeScope oldWidget) =>
      data != oldWidget.data;
}
