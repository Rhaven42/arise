import 'package:arise/core/anatomy/body_map.dart';
import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/exercises/presentation/animation/coach_video_demo.dart';
import 'package:arise/features/exercises/presentation/animation/figure_animation.dart';
import 'package:arise/features/exercises/presentation/exercise_detail_page.dart';
import 'package:arise/features/exercises/presentation/exercise_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('la liste affiche le catalogue et filtre par recherche', (
    tester,
  ) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.exercises);

    expect(find.text('Burpees'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'fente');
    await tester.pump();
    expect(find.text('Fentes'), findsOneWidget);
    expect(find.text('Burpees'), findsNothing);

    await tester.tap(find.text('Fentes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ExerciseDetailPage), findsOneWidget);
    await tester.unmountApp();
  });

  testWidgets(
    'la fiche montre le mannequin, les silhouettes et les consignes',
    (tester) async {
      final container = createTestContainer();
      await tester.openWithProfile(container, AppRoutes.exerciseDetail('row'));

      expect(find.text('Rowing'), findsOneWidget);
      // La vidéo du prof s'affiche après la liste des vidéos, avec pause.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('row-false')), findsOneWidget);
      await tester.tap(find.byKey(CoachVideoDemo.pauseKey));
      await tester.pump();
      expect(find.byTooltip("Lancer l'animation"), findsOneWidget);
      // En pause, l'image fixe remplace la vidéo.
      expect(find.byKey(const ValueKey('row-true')), findsOneWidget);
      // Les silhouettes sont sous le mannequin : un défilement les affiche.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
      await tester.pump();
      expect(find.byType(BodyMap), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('• Grand dorsal'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('• Grand dorsal'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Erreurs fréquentes'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Consignes'), findsOneWidget);
      await tester.unmountApp();
    },
  );

  testWidgets('animations réduites : pose fixe, sans bouton pause', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.exerciseDetail('row'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('row-true')), findsOneWidget);
    expect(find.byKey(CoachVideoDemo.pauseKey), findsNothing);
    await tester.unmountApp();
  });

  testWidgets('une variante a son propre mouvement', (tester) async {
    final container = createTestContainer();
    await tester.openWithProfile(
      container,
      AppRoutes.exerciseDetail('bird_dog'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final demo = tester.widget<CoachVideoDemo>(find.byType(CoachVideoDemo));
    expect(demo.motionId, 'bird_dog');
    expect(find.byKey(const ValueKey('bird_dog-false')), findsOneWidget);
    await tester.unmountApp();
  });

  testWidgets('un exercice personnalisé s’enregistre', (tester) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.customExerciseNew);

    await tester.enterText(find.byType(TextField), 'Gainage maison');
    await tester.pump();

    // Choix d'un muscle par la liste déroulante accessible.
    await tester.scrollUntilVisible(
      find.text('Ajouter un muscle depuis la liste'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ajouter un muscle depuis la liste'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Abducteurs').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.scrollUntilVisible(
      find.text('Enregistrer'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final saved = container.read(customExercisesProvider).value!;
    expect(saved.single.name, 'Gainage maison');
    expect(saved.single.primaryMuscles, [MuscleId.abductors]);
    expect(find.byType(ExerciseDetailPage), findsOneWidget);
    await tester.unmountApp();
  });

  testWidgets('sans muscle principal, l’enregistrement est refusé', (
    tester,
  ) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.customExerciseNew);

    await tester.enterText(find.byType(TextField), 'Sans muscle');
    await tester.scrollUntilVisible(
      find.text('Enregistrer'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();

    expect(find.text('Choisis au moins un muscle principal.'), findsOneWidget);
    expect(container.read(customExercisesProvider).value, isEmpty);
    await tester.unmountApp();
  });

  test('les mouvements de test sont chargés', () {
    expect(testMotions.keys, contains('squat'));
    expect(motionsAsset, endsWith('.json'));
  });
}
