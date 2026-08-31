import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/widgets/tap_scale.dart';

void main() {
  testWidgets('tapping invokes onTap and animates scale down then back up', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: TapScale(
            onTap: () => tapped++,
            child: const SizedBox(width: 100, height: 100, key: Key('child')),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(TapScale)),
    );
    await tester.pump();
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      0.96,
    );

    await gesture.up();
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1.0);

    await tester.pumpAndSettle();
    expect(tapped, 1);
  });

  testWidgets('a null onTap disables the gesture and never scales down', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: TapScale(child: SizedBox(width: 100, height: 100))),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(TapScale)),
    );
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1.0);
    await gesture.up();
  });
}
