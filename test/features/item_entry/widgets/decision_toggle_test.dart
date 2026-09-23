import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:skip/core/audio/sfx_player.dart';
import 'package:skip/core/localization/locale_provider.dart';
import 'package:skip/core/theme/app_themes.dart';
import 'package:skip/features/item_entry/widgets/decision_toggle.dart';

class _MockSfxPlayer extends Mock implements SkipSfxPlayer {}

void main() {
  late _MockSfxPlayer mockSfx;

  setUp(() {
    mockSfx = _MockSfxPlayer();
    when(() => mockSfx.playResisted()).thenAnswer((_) async {});
    when(() => mockSfx.dispose()).thenReturn(null);
  });

  Future<void> pumpToggle(
    WidgetTester tester, {
    required ThemeData theme,
    required bool? isSaved,
    required ValueChanged<bool?> onChanged,
    bool Function()? canSelect,
    bool hasSelection = true,
  }) {
    return tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LocaleProvider(),
        child: MaterialApp(
          theme: theme,
          home: Scaffold(
            body: DecisionToggle(
              isSaved: isSaved,
              onChanged: onChanged,
              hasSelection: hasSelection,
              canSelect: canSelect,
              sfxPlayer: mockSfx,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'Minimal theme: tapping options reports the choice, no confetti',
    (tester) async {
      bool? lastValue;
      await pumpToggle(
        tester,
        theme: AppThemes.minimal,
        isSaved: true,
        onChanged: (value) => lastValue = value,
      );

      await tester.tap(find.text('Bought It'));
      await tester.pumpAndSettle();
      expect(lastValue, isFalse);

      await tester.tap(find.text('Resisted!'));
      await tester.pumpAndSettle();
      expect(lastValue, isTrue);

      expect(find.byType(ConfettiWidget), findsNothing);
      verifyNever(() => mockSfx.playResisted());
    },
  );

  testWidgets(
    'Y2K theme: tapping Resisted! reports the choice and fires the SFX cue',
    (tester) async {
      bool? lastValue;
      await pumpToggle(
        tester,
        theme: AppThemes.y2k,
        isSaved: false,
        onChanged: (value) => lastValue = value,
      );

      // Not pumpAndSettle: ConfettiWidget keeps its internal ticker running
      // past its own `duration` (a known quirk of the confetti package), so
      // settling never naturally completes. A couple of bounded pumps are
      // enough to flush the tap's state change and the controller's
      // auto-stop timer without waiting on that ticker.
      await tester.tap(find.text('Resisted!'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(lastValue, isTrue);
      verify(() => mockSfx.playResisted()).called(1);
    },
  );

  testWidgets('Y2K theme: tapping Bought It does not fire the SFX cue', (
    tester,
  ) async {
    bool? lastValue;
    await pumpToggle(
      tester,
      theme: AppThemes.y2k,
      isSaved: true,
      onChanged: (value) => lastValue = value,
    );

    await tester.tap(find.text('Bought It'));
    await tester.pumpAndSettle();

    expect(lastValue, isFalse);
    verifyNever(() => mockSfx.playResisted());
  });

  testWidgets('tapping Pondering reports null', (tester) async {
    bool? lastValue = true;
    await pumpToggle(
      tester,
      theme: AppThemes.minimal,
      isSaved: true,
      onChanged: (value) => lastValue = value,
    );

    await tester.tap(find.text('Pondering'));
    await tester.pumpAndSettle();

    expect(lastValue, isNull);
  });

  testWidgets('Y2K theme: a rejected tap skips the celebration and onChanged', (
    tester,
  ) async {
    var called = false;
    await pumpToggle(
      tester,
      theme: AppThemes.y2k,
      isSaved: false,
      canSelect: () => false,
      onChanged: (_) => called = true,
    );

    await tester.tap(find.text('Resisted!'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(called, isFalse);
    verifyNever(() => mockSfx.playResisted());
  });

  group('selection display', () {
    Color? labelColor(WidgetTester tester, String label) =>
        tester.widget<Text>(find.text(label)).style?.color;

    testWidgets('hasSelection: false shows every option unselected', (
      tester,
    ) async {
      await pumpToggle(
        tester,
        theme: AppThemes.minimal,
        isSaved: null,
        hasSelection: false,
        onChanged: (_) {},
      );
      final unselected = AppThemes.minimal.colorScheme.onSurface;

      expect(labelColor(tester, 'Resisted!'), unselected);
      expect(labelColor(tester, 'Pondering'), unselected);
      expect(labelColor(tester, 'Bought It'), unselected);
    });

    testWidgets('a null decision with a selection highlights Pondering', (
      tester,
    ) async {
      await pumpToggle(
        tester,
        theme: AppThemes.minimal,
        isSaved: null,
        onChanged: (_) {},
      );

      expect(
        labelColor(tester, 'Pondering'),
        isNot(AppThemes.minimal.colorScheme.onSurface),
      );
    });
  });
}
