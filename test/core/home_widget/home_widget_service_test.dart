import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/home_widget/home_widget_service.dart';

void main() {
  group('widgetMonthKey', () {
    test('zero-pads the month', () {
      expect(widgetMonthKey(DateTime(2026, 3, 15)), '2026-03');
    });

    test('uses the local calendar month at the boundaries', () {
      expect(widgetMonthKey(DateTime(2026, 9, 30, 23, 59, 59)), '2026-09');
      expect(widgetMonthKey(DateTime(2026, 10, 1)), '2026-10');
      expect(widgetMonthKey(DateTime(2026, 12, 31, 23, 59)), '2026-12');
    });
  });
}
