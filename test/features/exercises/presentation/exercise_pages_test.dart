import 'package:arise/core/anatomy/body_map.dart';
import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/avatar/domain/character_scene.dart';
import 'package:arise/features/exercises/presentation/animation/character_exercise_demo.dart';
import 'package:arise/features/exercises/presentation/animation/figure_animation.dart';
import 'package:arise/features/exercises/presentation/exercise_detail_page.dart';
import 'package:arise/features/exercises/presentation/exercise_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_character_renderer.dart';
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

  testWidgets('la fiche montre l’animation, les silhouettes et les consignes', (
    tester,
  ) async {
    final renderer = FakeCharacterRenderer();
    final container = createTestContainer(renderer: renderer);
    await tester.openWithProfile(
      container,
      AppRoutes.exerciseDetail('push_up'),
    );

    expect(find.text('Pompes'), findsOneWidget);
    await tester.pump();
    // Le personnage (par défaut, faute de personnage créé) fait les pompes.
    expect(find.byType(CharacterExerciseDemo), findsOneWidget);
    expect(find.byType(FigureAnimation), findsNothing);
    expect(renderer.lastScene?.motion, 'push_up');
    expect(renderer.lastScene?.focus, SceneFocus.exerciseSide);
    expect(find.byType(BodyMap), findsNWidgets(2));
    await tester.scrollUntilVisible(
      find.text('• Triceps'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('• Triceps'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Erreurs fréquentes'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Consignes'), findsOneWidget);
    await tester.unmountApp();
  });

  testWidgets('animations réduites : le mannequin 2D remplace le personnage', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final container = createTestContainer();
    await tester.openWithProfile(
      container,
      AppRoutes.exerciseDetail('push_up'),
    );

    expect(find.byType(FigureAnimation), findsOneWidget);
    expect(find.text('rendu:human_female'), findsNothing);
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
