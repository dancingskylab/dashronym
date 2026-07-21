/// Inline glossary utilities for expanding acronyms in Flutter text.
///
/// This library turns known acronyms into tappable, accessible tooltip cards
/// without breaking reading flow. The primary surface is [DashronymText],
/// which renders strings using a [DashronymRegistry], [DashronymConfig], and
/// [DashronymTheme].
///
/// Quick start:
/// ```dart
/// // 1) Define your glossary.
/// final registry = DashronymRegistry({
///   'SDK': 'Software Development Kit',
///   'API': 'Application Programming Interface',
/// });
///
/// // 2) Render inline acronyms with DashronymText.
/// const text = 'Install the (SDK) to use the API.';
///
/// DashronymText(
///   text,
///   registry: registry,
///   config: const DashronymConfig(enableBareAcronyms: true),
///   theme: const DashronymTheme(underline: true),
/// );
///
/// // 3) Wire up localization (typically in MaterialApp):
/// MaterialApp(
///   localizationsDelegates: const [
///     // ...existing delegates,
///     DashronymLocalizations.delegate,
///   ],
///   supportedLocales: DashronymLocalizations.supportedLocales,
///   // ...
/// )
/// ```
///
/// Notes:
/// * Marker-wrapped acronyms are recognized per [DashronymConfig.acceptMarkers]
///   (e.g., `(SDK)`, `"API"`, `'API'`). When [DashronymConfig.enableBareAcronyms]
///   is `true`, bare ALL-CAPS words within length bounds also match.
/// * Tooltips announce their definition on supported assistive-technology
///   platforms and expose a semantic live region elsewhere.
/// * Styling (underline, thickness, offsets, fade durations, card size) is
///   controlled via [DashronymTheme].
library;

export 'dashronym_core.dart';
export 'src/dashronym_text.dart';
export 'src/dashronym_scope.dart';
export 'src/dashronym_text_extension.dart';
export 'src/dashronym_theme.dart';
export 'src/dashronym_localizations.dart';
export 'src/dashronym_inline.dart'
    show DashronymTooltipBuilder, DashronymTooltipDetails;
