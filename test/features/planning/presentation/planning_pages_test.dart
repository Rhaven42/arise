import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/planning/domain/planned_session.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/planning/presentation/planning_providers.dart';
import 'package:arise/features/planning/presentation/programs_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_reminder_scheduler.dart';
import '../../../helpers/test_app.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

const _program = Program(
  id: 'p1',
  name: 'Haut du corps',
  format: ProgramFormat.strength,
  items: [
    ProgramItem(exerciseId: 'push_up', sets: 3, reps: 12, restSeconds: 60),
  ],
);

void main() {
  testWidgets('créer un programme de musculation', (tester) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.programNew);

    await tester.enterText(find.byType(TextField), 'Jambes de fer');
    await tester.tap(find.text('Ajouter un exercice'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField).last, 'squat');
    await _settle(tester);
    await tester.tap(find.text('Squat').last);
    await _settle(tester);

    expect(find.text('Séries'), findsOneWidget);
    await tester.tap(find.byTooltip('Augmenter : Séries'));
    await tester.pump();
    expect(find.text('4'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Enregistrer'), 200);
    await tester.tap(find.text('Enregistrer'));
    await _settle(tester);

    expect(find.byType(ProgramsPage), findsOneWidget);
    final saved = container.read(programsProvider).value!.single;
    expect(saved.name, 'Jambes de fer');
    expect(saved.items.single.sets, 4);
    await tester.unmountApp();
  });

  testWidgets('un programme sans exercice est refusé', (tester) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.programNew);

    await tester.enterText(find.byType(TextField), 'Vide');
    await tester.scrollUntilVisible(find.text('Enregistrer'), 200);
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();

    expect(find.text('Ajoute au moins un exercice.'), findsOneWidget);
    await tester.unmountApp();
  });

  testWidgets('planifier une séance avec rappel', (tester) async {
    final reminders = FakeReminderScheduler();
    final container = createTestContainer(reminders: reminders);
    await container.read(programRepositoryProvider).save(_program);
    await tester.openWithProfile(container, AppRoutes.planning);

    // Lundi : ajout d'une séance.
    await tester.tap(find.byTooltip('Ajouter une séance le Lundi'));
    await _settle(tester);
    expect(find.text('Nouvelle séance'), findsOneWidget);
    await tester.tap(find.text('Enregistrer'));
    await _settle(tester);

    final sessions = container.read(plannedSessionsProvider).value!;
    expect(sessions.single.weekday, DateTime.monday);
    expect(sessions.single.programId, 'p1');
    expect(reminders.permissionRequests, 1);
    expect(find.text('Haut du corps'), findsOneWidget);
    await _settle(tester);
    expect(reminders.scheduled, hasLength(1));
    await tester.unmountApp();
  });

  testWidgets('un jour de repos refuse la musculation', (tester) async {
    final container = createTestContainer();
    await container.read(programRepositoryProvider).save(_program);
    await tester.openWithProfile(container, AppRoutes.planning);

    // Le profil de test se repose le mercredi.
    await tester.scrollUntilVisible(
      find.byTooltip('Ajouter une séance le Mercredi'),
      200,
    );
    await tester.tap(find.byTooltip('Ajouter une séance le Mercredi'));
    await _settle(tester);

    expect(
      find.textContaining('seuls les programmes de mobilité'),
      findsOneWidget,
    );
    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Enregistrer'),
    );
    expect(save.onPressed, isNull);
    await tester.unmountApp();
  });

  testWidgets('glisser une séance vers un autre jour', (tester) async {
    final container = createTestContainer();
    await container.read(programRepositoryProvider).save(_program);
    await container
        .read(planningRepositoryProvider)
        .save(
          const PlannedSession(
            id: 's1',
            programId: 'p1',
            weekday: DateTime.monday,
            minuteOfDay: 18 * 60,
          ),
        );
    await tester.openWithProfile(container, AppRoutes.planning);

    final chip = find.text('Haut du corps');
    final target = find.text('Aucune séance').first; // mardi
    final gesture = await tester.startGesture(tester.getCenter(chip));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    await gesture.up();
    await _settle(tester);

    expect(
      container.read(plannedSessionsProvider).value!.single.weekday,
      DateTime.tuesday,
    );
    await tester.unmountApp();
  });
}
