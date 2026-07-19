import 'package:dashronym/dashronym.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DashronymLocalizations returns fallback strings when not in tree', () {
    final strings = DashronymLocalizations(const Locale('en'));

    expect(
      strings.tooltipMessage('SDK', 'Software Development Kit'),
      'Show definition for SDK.\nSoftware Development Kit',
    );
    expect(
      strings.semanticsHintShow('SDK'),
      'Double tap to show definition for SDK.',
    );
    expect(
      strings.semanticsHintHide('SDK'),
      'Double tap to hide definition for SDK.',
    );
    expect(strings.announceTooltipShown('SDK'), 'Showing definition for SDK.');
    expect(
      strings.announceTooltipContent('SDK', 'Software Development Kit'),
      'Showing definition for SDK. Software Development Kit',
    );
    expect(strings.closeButtonTooltip('SDK'), 'Hide definition for SDK');
    expect(strings.semanticsBarrierLabel('SDK'), 'Hide definition for SDK.');
    expect(strings.closeButtonLabel('SDK'), 'Close definition for SDK');
    expect(strings.tooltipLabel('SDK'), 'Definition for SDK');
  });

  test('DashronymLocalizations delegate never reloads', () {
    const delegate = DashronymLocalizations.delegate;
    expect(delegate.isSupported(const Locale('en')), isTrue);
    expect(delegate.shouldReload(delegate), isFalse);
  });

  test('complete announcements preserve custom shown-message overrides', () {
    final strings = _CustomDashronymLocalizations(const Locale('en'));

    expect(
      strings.announceTooltipContent('SDK', 'Software Development Kit'),
      'Opening SDK. Software Development Kit',
    );
  });
}

final class _CustomDashronymLocalizations extends DashronymLocalizations {
  _CustomDashronymLocalizations(super.locale);

  @override
  String announceTooltipShown(String acronym) => 'Opening $acronym.';
}
