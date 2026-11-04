import 'package:arise/core/anatomy/body_map.dart';
import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/router/app_routes.dart';
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

  testWidgets('la fiche montre l’animation, les silhouettes et les consignes', (
    tester,
  ) async {
    final container = createTestContainer();
    await tester.openWithProfile(
      container,
      AppRoutes.exerciseDetail('push_up'),
    );

    expect(find.text('Pompes'), findsOneWidget);
    expect(find.byType(FigureAnimation), findsOneWidget);
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
    await tester.tap(find.text('Obliques').last);
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
    expect(saved.single.primaryMuscles, [MuscleId.obliques]);
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
