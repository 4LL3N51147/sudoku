import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/main.dart';

void main() {
  testWidgets('app renders difficulty screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SudokuApp());
    expect(find.text('SUDOKU'), findsOneWidget);
  });
}
