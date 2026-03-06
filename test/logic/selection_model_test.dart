import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/logic/selection_model.dart';

void main() {
  group('SelectionModel', () {
    late SelectionModel selection;

    setUp(() {
      selection = SelectionModel();
    });

    test('starts with no selection', () {
      expect(selection.row, -1);
      expect(selection.col, -1);
      expect(selection.hasSelection, false);
    });

    test('selects a cell', () {
      selection.select(3, 4);

      expect(selection.row, 3);
      expect(selection.col, 4);
      expect(selection.hasSelection, true);
    });

    test('clears selection', () {
      selection.select(3, 4);
      selection.clear();

      expect(selection.row, -1);
      expect(selection.col, -1);
      expect(selection.hasSelection, false);
    });

    test('can select different cells', () {
      selection.select(0, 0);
      expect(selection.row, 0);
      expect(selection.col, 0);

      selection.select(8, 8);
      expect(selection.row, 8);
      expect(selection.col, 8);
    });
  });
}
