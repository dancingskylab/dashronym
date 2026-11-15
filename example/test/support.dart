import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The open card, found through its public semantics label.
Finder get openCard => find.bySemanticsLabel('Definition for SDK');

/// The surface color of the open card.
Color cardSurface(WidgetTester tester) {
  return tester
      .widget<PhysicalShape>(
        find.descendant(of: openCard, matching: find.byType(PhysicalShape)),
      )
      .color;
}

/// Whether [color] is a dark surface.
bool isDark(Color color) => color.computeLuminance() < 0.179;
