import 'package:arise/features/character_creation/domain/edit_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('annule puis rétablit', () {
    var h = EditHistory.start(1).push(2).push(3);
    h = h.undo();
    expect(h.current, 2);
    h = h.undo();
    expect(h.current, 1);
    expect(h.canUndo, isFalse);
    h = h.redo();
    expect(h.current, 2);
    expect(h.canRedo, isTrue);
  });

  test('une nouvelle action efface les actions annulées', () {
    final h = EditHistory.start(1).push(2).undo().push(5);
    expect(h.current, 5);
    expect(h.canRedo, isFalse);
  });

  test('garde au plus 20 actions annulables', () {
    var h = EditHistory.start(0);
    for (var i = 1; i <= 25; i++) {
      h = h.push(i);
    }
    var undos = 0;
    while (h.canUndo) {
      h = h.undo();
      undos++;
    }
    expect(undos, 20);
    expect(h.current, 5);
  });

  test('une valeur identique ne crée pas d’action', () {
    final h = EditHistory.start(1).push(1);
    expect(h.canUndo, isFalse);
    expect(EditHistory.start(1).push(2).replace(9).undo().current, 1);
  });
}
