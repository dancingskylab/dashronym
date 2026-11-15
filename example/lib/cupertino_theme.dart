import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:dashronym/dashronym.dart';

// #region cupertino-recipe
/// Maps the ambient Cupertino theme onto a [DashronymTheme].
///
/// Install the result with a [DashronymThemeScope] in `CupertinoApp.builder`
/// to give the tooltip card system colors, type and SF Symbols-style icons.
DashronymTheme dashronymThemeFromCupertino(BuildContext context) {
  final theme = CupertinoTheme.of(context);
  final body = theme.textTheme.textStyle;
  return DashronymTheme(
    acronymStyle: TextStyle(color: theme.primaryColor),
    cardColor: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
      context,
    ),
    cardIconColor: theme.primaryColor,
    cardTitleStyle: body.copyWith(fontWeight: FontWeight.w600),
    cardSubtitleStyle: body.copyWith(
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
    ),
    cardIcon: CupertinoIcons.info,
    cardCloseIcon: CupertinoIcons.xmark,
  );
}
// #endregion cupertino-recipe
