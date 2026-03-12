import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/app_settings.dart';
import 'package:sudoku/widgets/settings_sheet.dart';

void main() {
  group('SettingsSheet', () {
    testWidgets('renders without overflow in constrained height', (tester) async {
      // Create a constrained surface to simulate small screen
      await tester.binding.setSurfaceSize(const Size(400, 300));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsSheet(
              settings: const AppSettings(),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the widget renders without overflow
      expect(tester.takeException(), isNull);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('displays all setting controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return SettingsSheet(
                  settings: const AppSettings(),
                  onChanged: (_) {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all switch controls are present
      expect(find.text('Skip Animation'), findsOneWidget);
      expect(find.text('Show Advanced Hints'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
