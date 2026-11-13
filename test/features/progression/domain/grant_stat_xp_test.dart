import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/progression_rules.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('grantStatXp ajoute de l XP de stat, jamais de Volonté', () {
    const state = ProgressionState(
      lastRolloverDay: CivilDate(2026, 11, 4),
      statXp: {StatId.endurance: 5},
    );
    final next = grantStatXp(state, {
      StatId.endurance: 10,
      StatId.vitality: 4,
      StatId.willpower: 50,
    });
    expect(next.statXp[StatId.endurance], 15);
    expect(next.statXp[StatId.vitality], 4);
    expect(next.statXp[StatId.willpower], isNull);
    expect(grantStatXp(state, const {}), same(state));
  });
}
