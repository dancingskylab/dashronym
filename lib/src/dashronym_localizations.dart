import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Localized strings used by dashronym widgets.
///
/// Provides phrases for tooltips, semantics, and announcements. Supply the
/// bundled [delegate] alongside Flutter's built-in localization delegates to
/// enable translations.
class DashronymLocalizations {
  /// Creates localization strings scoped to the given [locale].
  DashronymLocalizations(this.locale);

  /// The locale associated with these strings.
  final Locale locale;

  /// The locales supported by dashronym translations.
  static const supportedLocales = <Locale>[Locale('en')];

  /// The localization delegate that loads [DashronymLocalizations].
  static const LocalizationsDelegate<DashronymLocalizations> delegate =
      _DashronymLocalizationsDelegate();

  /// The localization resources for [context], falling back to English.
  ///
  /// Returns the ambient instance created by [delegate], or a new
  /// [DashronymLocalizations] configured for `'en'` when not found.
  static DashronymLocalizations of(BuildContext context) {
    final result = Localizations.of<DashronymLocalizations>(
      context,
      DashronymLocalizations,
    );
    return result ?? DashronymLocalizations(const Locale('en'));
  }

  /// A legacy combined tooltip message for custom surfaces.
  ///
  /// The stock card renders its title and description separately. This helper
  /// remains available to custom builders that want the earlier combined
  /// multi-line wording.
  String tooltipMessage(String acronym, String description) =>
      'Show definition for $acronym.\n$description';

  /// The semantics hint read before showing the tooltip.
  String semanticsHintShow(String acronym) =>
      'Double tap to show definition for $acronym.';

  /// The semantics hint read while the tooltip is visible.
  String semanticsHintHide(String acronym) =>
      'Double tap to hide definition for $acronym.';

  /// The base explicit-announcement phrase for a visible tooltip.
  ///
  /// [announceTooltipContent] calls this method so existing localization
  /// overrides remain effective while the complete definition is announced.
  String announceTooltipShown(String acronym) =>
      'Showing definition for $acronym.';

  /// The complete announcement used when the tooltip becomes visible.
  ///
  /// This includes the definition so assistive-technology users receive the
  /// same information as sighted users without having to move focus into the
  /// tooltip. It builds on [announceTooltipShown], preserving existing custom
  /// localization overrides.
  String announceTooltipContent(String acronym, String description) =>
      '${announceTooltipShown(acronym)} $description';

  /// The explicit announcement used after dismissing the tooltip.
  String announceTooltipHidden(String acronym) =>
      'Closed definition for $acronym.';

  /// A label available to custom semantic dismiss controls.
  ///
  /// Dashronym's built-in outside-tap layer is intentionally excluded from the
  /// semantics tree, so it does not call this helper.
  String semanticsBarrierLabel(String acronym) =>
      'Hide definition for $acronym.';

  /// The tooltip text used on the close button.
  String closeButtonTooltip(String acronym) => 'Hide definition for $acronym';

  /// A semantics label available to custom close buttons.
  ///
  /// The stock close button uses [closeButtonTooltip], which Flutter also
  /// exposes to assistive technology.
  String closeButtonLabel(String acronym) => 'Close definition for $acronym';

  /// The semantics label applied to the tooltip card container.
  String tooltipLabel(String acronym) => 'Definition for $acronym';
}

/// A delegate that synchronously loads [DashronymLocalizations] instances.
class _DashronymLocalizationsDelegate
    extends LocalizationsDelegate<DashronymLocalizations> {
  const _DashronymLocalizationsDelegate();

  /// Whether this delegate supports [locale].
  @override
  bool isSupported(Locale locale) {
    return DashronymLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  /// Loads localization resources for [locale].
  @override
  Future<DashronymLocalizations> load(Locale locale) =>
      SynchronousFuture(DashronymLocalizations(locale));

  /// Whether this delegate should reload when [old] changes.
  @override
  bool shouldReload(_DashronymLocalizationsDelegate old) => false;
}
