/// Accessible inline acronym definitions for Flutter text.
///
/// Define terms with [DashronymRegistry], then use [DashronymText] or
/// `Text.dashronyms()` to show their definitions without interrupting the
/// reading flow.
///
/// Quick start:
/// ```dart
/// final registry = DashronymRegistry({
///   'SDK': 'Software Development Kit',
///   'API': 'Application Programming Interface',
/// });
///
/// DashronymText(
///   'Install the SDK to use the API.',
///   registry: registry,
/// );
/// ```
library;

export 'src/dashronym_config.dart';
export 'src/dashronym_registry.dart';
export 'src/dashronym_text.dart';
export 'src/dashronym_scope.dart';
export 'src/dashronym_text_extension.dart';
export 'src/dashronym_theme.dart';
export 'src/dashronym_theme_scope.dart';
export 'src/dashronym_localizations.dart';
export 'src/dashronym_inline.dart'
    show DashronymTooltipBuilder, DashronymTooltipDetails;
