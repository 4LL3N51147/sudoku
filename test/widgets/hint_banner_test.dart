import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/widgets/hint_banner.dart';

void main() {
  group('HintBanner', () {
    testWidgets('displays message text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HintBanner(message: 'Test hint message'),
          ),
        ),
      );

      expect(find.text('Test hint message'), findsOneWidget);
    });

    testWidgets('displays info icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HintBanner(message: 'Test'),
          ),
        ),
      );

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('shows Next button when hasNextButton is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HintBanner(
              message: 'Test',
              hasNextButton: true,
              onNextPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Next →'), findsOneWidget);
    });

    testWidgets('hides Next button when hasNextButton is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HintBanner(
              message: 'Test',
              hasNextButton: false,
            ),
          ),
        ),
      );

      expect(find.text('Next →'), findsNothing);
    });

    testWidgets('calls onNextPressed when Next button is tapped', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HintBanner(
              message: 'Test',
              hasNextButton: true,
              onNextPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Next →'));
      expect(pressed, true);
    });
  });
}
