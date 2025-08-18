import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akel_panic_button/widgets/panic_button.dart';

void main() {
  group('PanicButton Widget Tests', () {
    testWidgets('PanicButton displays correctly', (WidgetTester tester) async {
      bool wasPressed = false;
      bool wasLongPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanicButton(
              onPressed: () => wasPressed = true,
              onLongPress: () => wasLongPressed = true,
            ),
          ),
        ),
      );

      // Verify the button is displayed
      expect(find.text('EMERGENCY'), findsOneWidget);
      expect(find.text('PANIC'), findsOneWidget);
      expect(find.text('Tap for alert • Hold for silent'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);

      // Test tap functionality
      await tester.tap(find.byType(PanicButton));
      await tester.pump();

      expect(wasPressed, isTrue);
      expect(wasLongPressed, isFalse);
    });

    testWidgets('PanicButton handles long press', (WidgetTester tester) async {
      bool wasPressed = false;
      bool wasLongPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanicButton(
              onPressed: () => wasPressed = true,
              onLongPress: () => wasLongPressed = true,
            ),
          ),
        ),
      );

      // Test long press functionality
      await tester.longPress(find.byType(PanicButton));
      await tester.pump();

      expect(wasLongPressed, isTrue);
    });

    testWidgets('PanicButton animation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanicButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.byType(PanicButton), findsOneWidget);

      // Let some animation frames pass
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));

      // Button should still be there after animations
      expect(find.byType(PanicButton), findsOneWidget);
    });

    testWidgets('PanicButton respects custom size', (WidgetTester tester) async {
      const customSize = 150.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanicButton(
              onPressed: () {},
              size: customSize,
            ),
          ),
        ),
      );

      final buttonWidget = tester.widget<Container>(
        find.descendant(
          of: find.byType(PanicButton),
          matching: find.byType(Container),
        ).first,
      );

      expect(buttonWidget.constraints?.maxWidth, customSize);
      expect(buttonWidget.constraints?.maxHeight, customSize);
    });
  });
}