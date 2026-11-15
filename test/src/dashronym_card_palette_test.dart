import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_card_palette.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _black = Color(0xFF000000);
const _white = Color(0xFFFFFFFF);

/// Resolves a palette under the given host signals.
Future<DashronymCardPalette> _resolve(
  WidgetTester tester, {
  DashronymTheme theme = const DashronymTheme(),
  Color? textColor,
  Color? hint,
  Color? iconColor,
  Brightness platformBrightness = Brightness.light,
  bool highContrast = false,
}) async {
  late DashronymCardPalette palette;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        platformBrightness: platformBrightness,
        highContrast: highContrast,
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: textColor),
        child: IconTheme(
          data: IconThemeData(color: iconColor),
          child: Builder(
            builder: (context) {
              palette = DashronymCardPalette.resolve(
                context,
                theme,
                textColorHint: hint,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  return palette;
}

/// Resolves the trigger focus highlight under the given host signals.
Future<Color> _focusHighlight(
  WidgetTester tester, {
  DashronymTheme theme = const DashronymTheme(),
  Color? textColor,
  Color? ambientColor,
  bool highContrast = false,
}) async {
  late Color color;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(highContrast: highContrast),
      child: DefaultTextStyle(
        style: TextStyle(color: ambientColor),
        child: Builder(
          builder: (context) {
            color = DashronymCardPalette.focusHighlight(
              context,
              theme,
              textColor,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return color;
}

void main() {
  testWidgets('explicit theme colors win', (tester) async {
    const border = BorderSide(color: Color(0xFF79747E), width: 2);
    final palette = await _resolve(
      tester,
      textColor: _black,
      theme: const DashronymTheme(
        cardColor: Color(0xFF123456),
        cardIconColor: Color(0xFFFFC107),
        cardShadowColor: Color(0xFF101010),
        cardBorderSide: border,
      ),
    );

    expect(palette.surface, const Color(0xFF123456));
    expect(palette.icon, const Color(0xFFFFC107));
    expect(palette.shadow, const Color(0xFF101010));
    expect(palette.border, border);
  });

  testWidgets('dark text implies a light card', (tester) async {
    final palette = await _resolve(tester, textColor: _black);

    expect(palette.surface, DashronymCardPalette.lightSurface);
    expect(palette.foreground, _black);
    expect(palette.shadow, _black);
    expect(palette.border, BorderSide.none);
  });

  testWidgets('light text implies a dark card', (tester) async {
    final palette = await _resolve(tester, textColor: _white);

    expect(palette.surface, DashronymCardPalette.darkSurface);
    expect(palette.foreground, _white);
  });

  testWidgets('without a text color the platform brightness decides', (
    tester,
  ) async {
    final dark = await _resolve(tester, platformBrightness: Brightness.dark);
    expect(dark.surface, DashronymCardPalette.darkSurface);
    expect(dark.foreground, DashronymCardPalette.darkForeground);

    final light = await _resolve(tester);
    expect(light.surface, DashronymCardPalette.lightSurface);
    expect(light.foreground, DashronymCardPalette.lightForeground);
  });

  testWidgets('the trigger color picks the surface', (tester) async {
    // Light trigger text in a light app, such as a dark banner, gets a dark
    // card. The app's dark body text lacks contrast there, so the card falls
    // back to a neutral light foreground.
    final banner = await _resolve(tester, textColor: _black, hint: _white);
    expect(banner.surface, DashronymCardPalette.darkSurface);
    expect(banner.foreground, DashronymCardPalette.darkForeground);

    // A brand-colored trigger keeps the app's body text color in the card.
    final branded = await _resolve(
      tester,
      textColor: _black,
      hint: const Color(0xFF3F51B5),
    );
    expect(branded.surface, DashronymCardPalette.lightSurface);
    expect(branded.foreground, _black);
  });

  testWidgets('low-contrast text falls back to a neutral foreground', (
    tester,
  ) async {
    // 38% black over white is well below 4.5:1.
    final faint = await _resolve(tester, textColor: const Color(0x61000000));
    expect(faint.surface, DashronymCardPalette.lightSurface);
    expect(faint.foreground, DashronymCardPalette.lightForeground);

    // Mid grey, such as a caption, reads on either surface, so the platform
    // brightness decides. It lacks contrast on both, so the text is neutral.
    const grey = Color(0xFF888888);
    final onLight = await _resolve(tester, textColor: grey);
    expect(onLight.surface, DashronymCardPalette.lightSurface);
    expect(onLight.foreground, DashronymCardPalette.lightForeground);
    final onDark = await _resolve(
      tester,
      textColor: grey,
      platformBrightness: Brightness.dark,
    );
    expect(onDark.surface, DashronymCardPalette.darkSurface);
    expect(onDark.foreground, DashronymCardPalette.darkForeground);
  });

  testWidgets('icons use the ambient icon color only when it contrasts', (
    tester,
  ) async {
    final branded = await _resolve(
      tester,
      textColor: _black,
      iconColor: const Color(0xFF1565C0),
    );
    expect(branded.icon, const Color(0xFF1565C0));

    final washedOut = await _resolve(
      tester,
      textColor: _black,
      iconColor: const Color(0xFFEEEEEE),
    );
    expect(washedOut.icon, _black);
  });

  testWidgets('high contrast adds an outline in the text color', (
    tester,
  ) async {
    final palette = await _resolve(
      tester,
      textColor: _black,
      highContrast: true,
    );

    expect(palette.border, const BorderSide(color: _black));
  });

  testWidgets('the close tooltip bubble contrasts with the card', (
    tester,
  ) async {
    final onLight = await _resolve(tester, textColor: _black);
    expect(onLight.bubbleColor, DashronymCardPalette.darkBubble);
    expect(onLight.bubbleTextColor, _white);

    final onDark = await _resolve(tester, textColor: _white);
    expect(onDark.bubbleColor, DashronymCardPalette.lightBubble);
    expect(onDark.bubbleTextColor, _black);
  });

  test('contrastRatio matches WCAG reference values', () {
    expect(DashronymCardPalette.contrastRatio(_black, _white), 21);
    expect(DashronymCardPalette.contrastRatio(_white, _white), 1);
    expect(
      DashronymCardPalette.contrastRatio(const Color(0xFF767676), _white),
      closeTo(4.54, 0.01),
    );
  });

  group('focusHighlight', () {
    testWidgets('uses the theme color when set', (tester) async {
      final color = await _focusHighlight(
        tester,
        theme: const DashronymTheme(acronymFocusColor: Color(0x33FF0000)),
        textColor: _black,
      );
      expect(color, const Color(0x33FF0000));
    });

    testWidgets('tints the trigger text color', (tester) async {
      final normal = await _focusHighlight(tester, textColor: _white);
      expect(normal, _white.withValues(alpha: 0.12));

      final strong = await _focusHighlight(
        tester,
        textColor: _white,
        highContrast: true,
      );
      expect(strong, _white.withValues(alpha: 0.24));
    });

    testWidgets('falls back to the ambient text color, then black', (
      tester,
    ) async {
      final ambient = await _focusHighlight(
        tester,
        ambientColor: const Color(0xFF1565C0),
      );
      expect(ambient, const Color(0xFF1565C0).withValues(alpha: 0.12));

      final fallback = await _focusHighlight(tester);
      expect(fallback, _black.withValues(alpha: 0.12));
    });
  });
}
