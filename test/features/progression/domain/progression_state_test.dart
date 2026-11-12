import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final perPoint = gameConfig.progression.statXpPerPoint;
  final base = ProgressionState.initial(const CivilDate(2026, 11, 12));

  test('points placés et gagnés composent la valeur d’une stat', () {
    final state = base.copyWith(
      allocatedStats: {StatId.strength: 2},
      statXp: {StatId.strength: perPoint * 3 + 10},
    );
    expect(state.allocatedIn(StatId.strength), 2);
    expect(state.stat(StatId.strength), 5);
    expect(state.allocatedIn(StatId.agility), 0);
  });

  test('XP vers le prochain point automatique', () {
    final state = base.copyWith(statXp: {StatId.endurance: perPoint + 7});
    expect(state.statXpTowardNextPoint(StatId.endurance), 7);
    expect(state.statXpTowardNextPoint(StatId.vitality), 0);
    // La Volonté ne se gagne que par la régularité.
    expect(state.statXpTowardNextPoint(StatId.willpower), isNull);
  });
}
