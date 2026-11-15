/// Tooltip card widget used by Dashronym inline controls.
///
/// The card caps its width using the viewport and theme-provided limits,
/// letting the subtitle wrap naturally across multiple lines while keeping the
/// title constrained to a single line with ellipsis. This maintains a tidy
/// layout without bespoke text measurement logic.
library;

import 'package:flutter/widgets.dart';

import 'dashronym_card_palette.dart';
import 'dashronym_close_button.dart';
import 'dashronym_glyphs.dart';
import 'dashronym_localizations.dart';
import 'dashronym_theme.dart';
import 'dashronym_tooltip_constraints.dart';

/// A compact, accessible tooltip card displaying an acronym and its description.
///
/// The card is built from widgets-layer primitives and needs no design system.
/// Colors and icons that [theme] leaves unset are derived from the host app;
/// see [DashronymTheme.cardColor] and [DashronymTheme.cardIcon].
///
/// ### Sizing rules
/// The card caps its width to the tightest available limit from the viewport or
/// theme. The description wraps with natural word breaks. When
/// [DashronymTheme.tooltipMaxWidth] is set, it overrides the portrait fallback
/// to [DashronymTheme.cardWidth]. The acronym stays a single trimmed line.
///
/// ### Example
/// ```dart
/// DashronymTooltipCard(
///   acronym: 'SDK',
///   description: 'Software Development Kit',
///   theme: theme,
///   onClose: () => Navigator.of(context).maybePop(),
/// )
/// ```
class const DashronymTooltipCard({
  super.key,

  /// The short acronym shown as the title (e.g., `"SDK"`).
  required final String acronym,

  /// The full definition associated with [acronym].
  required final String description,

  /// The effective theme controlling spacing, radii, typography and caps.
  required final DashronymTheme theme,

  /// Invoked when the trailing close button is pressed.
  required final VoidCallback onClose,

  /// The trigger's resolved text color, used to pick a contrasting surface.
  final Color? textColorHint,
}) extends StatelessWidget {
  /// Creates a [DashronymTooltipCard].
  ///
  /// See the class docs for sizing rules and an example.
  this;

  /// Content widths below this hide the decorative leading glyph, so the
  /// title, description and close button keep their room.
  static const double _minWidthForGlyph = 160;

  /// Minimum row height, matching a two-line Material 3 list tile.
  static const double _minRowHeight = 72;

  /// Gap between the glyph, the text and the close button.
  static const double _gap = 16;

  /// Builds the tooltip card.
  @override
  Widget build(BuildContext context) {
    final strings = DashronymLocalizations.of(context);
    final mq = MediaQuery.maybeOf(context);
    final palette = DashronymCardPalette.resolve(
      context,
      theme,
      textColorHint: textColorHint,
    );
    final base = DefaultTextStyle.of(context).style;
    final titleStyle = base
        .merge(
          TextStyle(
            color: palette.foreground,
            fontWeight: .w700,
            decoration: TextDecoration.none,
          ),
        )
        .merge(theme.cardTitleStyle);
    final subtitleStyle = base
        .merge(
          TextStyle(
            color: palette.foreground,
            decoration: TextDecoration.none,
          ),
        )
        .merge(theme.cardSubtitleStyle);
    final leading = theme.cardIcon == null
        ? DashronymGlyphIcon(DashronymGlyph.info, color: palette.icon)
        : Icon(theme.cardIcon, color: palette.icon, size: 24);

    Widget content = SingleChildScrollView(
      primary: false,
      child: Padding(
        padding: theme.cardPadding,
        child: Padding(
          padding: theme.cardContentPadding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showGlyph = constraints.maxWidth >= _minWidthForGlyph;
              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _minRowHeight),
                child: Row(
                  children: [
                    if (showGlyph) ...[
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: theme.cardMinLeadingWidth,
                        ),
                        child: Center(widthFactor: 1, child: leading),
                      ),
                      const SizedBox(width: _gap),
                    ],
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: .min,
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              acronym,
                              style: titleStyle,
                              maxLines: 1,
                              softWrap: false,
                              overflow: .ellipsis,
                              textWidthBasis: TextWidthBasis.longestLine,
                            ),
                            Text(
                              description,
                              style: subtitleStyle,
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: _gap),
                    DashronymCloseButton(
                      tooltip: strings.closeButtonTooltip(acronym),
                      onPressed: onClose,
                      palette: palette,
                      icon: theme.cardCloseIcon,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(theme.cardBorderRadius),
    );
    if (palette.border != BorderSide.none) {
      content = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: ShapeDecoration(
          shape: shape.copyWith(side: palette.border),
        ),
        child: content,
      );
    }
    final card = PhysicalShape(
      clipper: ShapeBorderClipper(
        shape: shape,
        textDirection: Directionality.maybeOf(context),
      ),
      clipBehavior: .antiAlias,
      elevation: theme.cardElevation,
      color: palette.surface,
      shadowColor: palette.shadow,
      child: content,
    );

    Widget result = card;
    if (DashronymTooltipConstraintScope.maybeOf(context) == null) {
      result = LayoutBuilder(
        builder: (context, constraints) {
          final mqForBuilder = MediaQuery.maybeOf(context);
          final tooltipConstraints = DashronymTooltipConstraints.resolve(
            constraints: constraints,
            mediaQuery: mqForBuilder ?? mq,
            theme: theme,
          );
          return DashronymTooltipConstraintScope(
            constraints: tooltipConstraints,
            child: ConstrainedBox(
              constraints: tooltipConstraints,
              child: card,
            ),
          );
        },
      );
    }

    return Semantics(
      container: true,
      // Platforms that support explicit announcements use the single
      // announcement emitted by DashronymInline. Other platforms can discover
      // the newly inserted semantic live region without a disruptive event.
      liveRegion: !MediaQuery.supportsAnnounceOf(context),
      label: strings.tooltipLabel(acronym),
      value: description,
      child: result,
    );
  }
}
