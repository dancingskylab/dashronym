import 'package:dashronym/dashronym.dart';
import 'package:material_ui/material_ui.dart';

// #region material-recipe
/// Maps a Material [ThemeData] onto a [DashronymTheme].
///
/// Dashronym does not depend on Material. Install the result with a
/// [DashronymThemeScope] in `MaterialApp.builder` to give the tooltip card
/// Material colors, type and icons. The builder runs below `AnimatedTheme`, so
/// the card follows light, dark and animated theme changes.
DashronymTheme dashronymThemeFromMaterial(ThemeData theme) {
  final colors = theme.colorScheme;
  return DashronymTheme(
    acronymStyle: TextStyle(color: colors.primary),
    acronymFocusColor: theme.focusColor,
    cardColor: colors.surface,
    cardShadowColor: colors.shadow,
    cardIconColor: colors.primary,
    cardTitleStyle: theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: colors.onSurface,
    ),
    cardSubtitleStyle: theme.textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    ),
    cardIcon: Icons.info_outline,
    cardCloseIcon: Icons.close,
  );
}
// #endregion material-recipe
