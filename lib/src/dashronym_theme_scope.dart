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
/// The scope works in any app, whatever its design system. It is an
/// [InheritedTheme], so routes that capture themes (such as dialogs and menus)
/// carry it into their overlays.
///
/// Dashronym resolves its theme from a `theme` passed to the widget, then the
/// nearest [DashronymThemeScope], then the package defaults. Each
/// [DashronymScope] provides its [DashronymScope.theme] as a scope too, so the
/// nearest of the two wins.
///
/// Colors and icons the theme leaves unset are derived from the host app's
/// widgets-layer theming, such as [DefaultTextStyle] and [IconTheme], so a
/// Material, Cupertino or custom app gets a matching card without extra
/// configuration.
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
