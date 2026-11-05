import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/planning/presentation/planning_providers.dart';
import 'package:arise/features/workout_player/presentation/workout_cues.dart';
import 'package:arise/features/workout_player/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_workout_cues.dart';
import '../../../helpers/test_app.dart';

const _strength = Program(
  id: 'p1',
  name: 'Haut du corps',
  format: ProgramFormat.strength,
  items: [ProgramItem(exerciseId: 'push_up', sets: 1, reps: 10)],
);

const _tabata = Program(
  id: 'p2',
  name: 'Tabata express',
  format: ProgramFormat.interval,
  items: [ProgramItem(exerciseId: 'burpee')],
  interval: IntervalSettings(
    workSeconds: 20,
    restSeconds: 10,
    rounds: 2,
    cycles: 1,
    restBetweenCyclesSeconds: 60,
  ),
);

void main() {
  late DateTime now;
  late FakeWorkoutCues cues;

  setUp(() {
    now = testNow;
    cues = FakeWorkoutCues();
  });

  Future<ProviderContainer> open(WidgetTester tester, Program program) async {
    final container = createTestContainer(clock: () => now, cues: cues);
    await container.read(programRepositoryProvider).save(program);
    await tester.openWithProfile(container, AppRoutes.workout(program.id));
    await tester.pump(const Duration(milliseconds: 300));
    return container;
  }

  /// Avance l'horloge et laisse le minuteur du lecteur tourner.
  Future<void> advance(WidgetTester tester, int seconds) async {
    now = now.add(Duration(seconds: seconds));
    await tester.pump(workoutTickInterval);
    await tester.pump(workoutTickInterval);
  }

  testWidgets('une série terminée demande l’intensité puis affiche le bilan', (
    tester,
  ) async {
    final container = await open(tester, _strength);

    expect(find.text('Pompes'), findsWidgets);
    expect(find.textContaining('Série 1 sur 1'), findsOneWidget);
    expect(cues.screenOn, isTrue);
    expect(cues.sounds, [CueSound.start]);

    await advance(tester, 30);
    await tester.tap(find.text('Série terminée'));
    await tester.pump();
    expect(find.text('Intensité ressentie'), findsOneWidget);

    await tester.tap(find.text('7'));
    await tester.pump();
    expect(find.textContaining('Dur'), findsOneWidget);
    await tester.tap(find.text('Valider'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Séance terminée'), findsOneWidget);
    expect(find.textContaining('XP'), findsWidgets);
    expect(find.text('Muscles travaillés'), findsOneWidget);
    expect(cues.sounds.last, CueSound.finish);
    expect(cues.screenOn, isFalse);

    final saved = await container
        .read(completedSessionRepositoryProvider)
        .readAll();
    expect(saved.single.completed, isTrue);
    expect(saved.single.sets.single.rpe, 7);
    expect(saved.single.xpEarned, greaterThan(0));

    await tester.unmountApp();
  });

  testWidgets('les comptes à rebours enchaînent travail, repos et bilan', (
    tester,
  ) async {
    final container = await open(tester, _tabata);
    expect(find.text('Burpees'), findsWidgets);
    expect(find.textContaining('Round 1 sur 2'), findsOneWidget);

    await advance(tester, 17);
    expect(cues.sounds.where((s) => s == CueSound.countdown), isNotEmpty);
    await advance(tester, 4);
    expect(find.text('Repos'), findsOneWidget);
    expect(cues.sounds, contains(CueSound.rest));

    await advance(tester, 10);
    expect(find.textContaining('Round 2 sur 2'), findsOneWidget);
    await advance(tester, 21);

    expect(
      find.text("Intensité ressentie sur l'ensemble de la séance"),
      findsOneWidget,
    );
    await tester.tap(find.text('6'));
    await tester.pump();
    await tester.tap(find.text('Valider'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Séance terminée'), findsOneWidget);
    final saved = await container
        .read(completedSessionRepositoryProvider)
        .readAll();
    expect(saved.single.sets, hasLength(2));
    expect(saved.single.sets.every((s) => s.rpe == 6), isTrue);
    expect(saved.single.activeSeconds, 40);

    await tester.unmountApp();
  });

  testWidgets(
    'le bouton douleur arrête la séance avec un message de prudence',
    (tester) async {
      final container = await open(tester, _tabata);

      await tester.ensureVisible(find.text('Douleur ou malaise'));
      await tester.tap(find.text('Douleur ou malaise'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Arrête-toi maintenant'), findsOneWidget);
      expect(find.text('Séance interrompue'), findsOneWidget);
      final saved = await container
          .read(completedSessionRepositoryProvider)
          .readAll();
      expect(saved.single.stoppedForPain, isTrue);
      expect(saved.single.completed, isFalse);

      await tester.unmountApp();
    },
  );

  testWidgets('la pause gèle le minuteur', (tester) async {
    await open(tester, _tabata);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.text('En pause'), findsOneWidget);
    await advance(tester, 60);
    expect(find.textContaining('Round 1 sur 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Reprendre'));
    await tester.pump();
    expect(find.text('En pause'), findsNothing);

    await tester.unmountApp();
  });

  testWidgets('un programme introuvable affiche un message', (tester) async {
    final container = createTestContainer(clock: () => now, cues: cues);
    await tester.openWithProfile(container, AppRoutes.workout('absent'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text("Ce programme n'existe plus."), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.unmountApp();
  });
}
