import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/widgets/pause_overlay.dart';

void main() {
  group('PauseOverlay', () {
    testWidgets('displays pause icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              PauseOverlay(
                onResume: () {},
                onQuit: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.pause_circle_filled_rounded), findsOneWidget);
    });

    testWidgets('displays "Game Paused" text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              PauseOverlay(
                onResume: () {},
                onQuit: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.text('Game Paused'), findsOneWidget);
    });

    testWidgets('displays Resume button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              PauseOverlay(
                onResume: () {},
                onQuit: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.text('Resume'), findsOneWidget);
    });

    testWidgets('calls onResume when Resume button is pressed', (tester) async {
      var resumed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              PauseOverlay(
                onResume: () => resumed = true,
                onQuit: () {},
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Resume'));
      expect(resumed, true);
    });

    testWidgets('calls onQuit when Quit button is pressed', (tester) async {
      var quit = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              PauseOverlay(
                onResume: () {},
                onQuit: () => quit = true,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Quit'));
      expect(quit, true);
    });
  });
}
