import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('game_screen should have only one share_outlined button', () {
    final file = File('lib/screens/game_screen.dart');
    final content = file.readAsStringSync();

    // Count occurrences of Icons.share_outlined
    final matches = 'Icons.share_outlined'.allMatches(content);
    final count = matches.length;

    expect(count, 1, reason: 'Found $count occurrences of Icons.share_outlined, expected exactly 1');
  });
}
