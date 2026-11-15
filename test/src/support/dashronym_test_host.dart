import 'package:dashronym/dashronym.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page background of the widgets-only test host.
const hostBackground = Color(0xFFFFFBFE);

/// Body text of the widgets-only test host, similar to a typical app.
const hostTextStyle = TextStyle(
  color: Color(0xFF1C1B1F),
  fontSize: 14,
  height: 1.43,
  letterSpacing: 0.25,
);

/// Wraps [home] in a design-system-free app with Dashronym localizations.
///
/// [TestWidgetsApp] provides the navigator and overlay that tooltips need,
/// without Material or Cupertino.
Widget testHost(
  Widget home, {
  TextStyle textStyle = hostTextStyle,
  Color background = hostBackground,
  Map<ShortcutActivator, Intent>? shortcuts,
  TransitionBuilder? builder,
}) {
  return TestWidgetsApp(
    color: background,
    textStyle: textStyle,
    shortcuts: shortcuts,
    builder: builder,
    localizationsDelegates: const [DashronymLocalizations.delegate],
    home: ColoredBox(color: background, child: home),
  );
}

/// A page with the host background and body text, standing in for a scaffold.
class TestPage extends StatelessWidget {
  /// Creates a page that shows [body].
  const TestPage({super.key, required this.body});

  /// The page content.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: hostTextStyle,
      child: ColoredBox(color: hostBackground, child: body),
    );
  }
}
