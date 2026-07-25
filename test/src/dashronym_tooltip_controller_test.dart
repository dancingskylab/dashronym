import 'package:dashronym/src/dashronym_tooltip_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashronymTooltipController', () {
    test('replaces the active owner without clearing its replacement', () {
      final controller = DashronymTooltipController();
      final first = Object();
      final second = Object();
      final third = Object();
      var firstDismissals = 0;
      var secondDismissals = 0;

      controller.activate(first, () {
        firstDismissals++;
        controller.release(first);
      });
      controller.activate(second, () {
        secondDismissals++;
        controller.release(second);
      });

      expect(firstDismissals, 1);

      controller.release(first);
      controller.activate(third, () {});

      expect(secondDismissals, 1);
    });

    test('reactivating the same owner does not dismiss itself', () {
      final controller = DashronymTooltipController();
      final owner = Object();
      final replacement = Object();
      var firstCallbackCalls = 0;
      var updatedCallbackCalls = 0;

      controller.activate(owner, () {
        firstCallbackCalls++;
      });
      controller.activate(owner, () {
        updatedCallbackCalls++;
      });
      controller.activate(replacement, () {});

      expect(firstCallbackCalls, 0);
      expect(updatedCallbackCalls, 1);
    });
  });
}
