import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/health/presentation/health_providers.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_health_source.dart';
import '../../../helpers/test_app.dart';

final HealthConfig _c = gameConfig.health;

Future<ProviderContainer> _container(
  FakeHealthSource source, {
  bool consent = true,
}) async {
  final container = createTestContainer(health: source);
  addTearDown(container.dispose);
  await container
      .read(profileRepositoryProvider)
      .saveProfile(sampleProfile.copyWith(healthConsent: consent));
  return container;
}

Future<int> _statXp(ProviderContainer container, StatId stat) async {
  final state = await container.read(progressionRepositoryProvider).read();
  return state?.statXp[stat] ?? 0;
}

void main() {
  final today = CivilDate.ofLocal(testNow);
  final todayStart = DateTime(today.year, today.month, today.day);

  test('sans autorisation, rien n est lu sur le téléphone', () async {
    final source = FakeHealthSource();
    final container = await _container(source, consent: false);
    await container.read(healthControllerProvider.future);
    await container.read(healthControllerProvider.notifier).sync();

    expect(source.authorizeCalls, 0);
    expect(
      container.read(healthControllerProvider).value?.status,
      HealthSyncStatus.disabled,
    );
  });

  test('un refus du téléphone est signalé sans rien verser', () async {
    final source = FakeHealthSource(granted: false);
    final container = await _container(source);
    await container.read(healthControllerProvider.future);
    await container.read(healthControllerProvider.notifier).sync();

    expect(
      container.read(healthControllerProvider).value?.status,
      HealthSyncStatus.denied,
    );
    expect(await _statXp(container, StatId.endurance), 0);
  });

  test('une lecture qui échoue est signalée', () async {
    final source = FakeHealthSource()..fails = true;
    final container = await _container(source);
    await container.read(healthControllerProvider.future);
    await container.read(healthControllerProvider.notifier).sync();

    expect(
      container.read(healthControllerProvider).value?.status,
      HealthSyncStatus.failed,
    );
  });

  test('les pas et le sommeil du jour sont versés une seule fois', () async {
    final source = FakeHealthSource(
      days: {
        todayStart: (
          steps: _c.stepsPerBlock * 4,
          activities: const [],
          sleepMinutes: _c.sleepBonusMinHours * 60,
        ),
      },
    );
    final container = await _container(source);
    await container.read(healthControllerProvider.future);
    final controller = container.read(healthControllerProvider.notifier);

    await controller.sync();
    await controller.sync();

    final view = container.read(healthControllerProvider).value!;
    expect(view.status, HealthSyncStatus.synced);
    expect(view.today.steps, _c.stepsPerBlock * 4);
    expect(await _statXp(container, StatId.endurance), 4 * _c.xpPerStepBlock);
    expect(await _statXp(container, StatId.vitality), _c.sleepBonusXp);
    expect(view.todayXp, {
      StatId.endurance: 4 * _c.xpPerStepBlock,
      StatId.vitality: _c.sleepBonusXp,
    });

    // L'historique est enregistré sur le téléphone.
    final saved = await container.read(healthRepositoryProvider).read();
    expect(saved.dayOf(today).steps, _c.stepsPerBlock * 4);
  });

  test('l objectif d hydratation rapporte de la Vitalité une fois', () async {
    final container = await _container(FakeHealthSource());
    await container.read(healthControllerProvider.future);
    final controller = container.read(healthControllerProvider.notifier);

    for (var i = 0; i < _c.hydrationGoalGlasses; i++) {
      await controller.addGlass(1);
    }
    expect(await _statXp(container, StatId.vitality), _c.hydrationBonusXp);

    // Retirer puis remettre un verre ne paie pas deux fois.
    await controller.addGlass(-1);
    await controller.addGlass(1);
    expect(await _statXp(container, StatId.vitality), _c.hydrationBonusXp);
    expect(
      container.read(healthControllerProvider).value?.today.glasses,
      _c.hydrationGoalGlasses,
    );
  });
}
