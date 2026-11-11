import 'package:arise/core/anatomy/body_map.dart';
import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/exercises/presentation/animation/exercise_photo_demo.dart';
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

  testWidgets('la fiche montre les photos, les silhouettes et les consignes', (
    tester,
  ) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.exerciseDetail('row'));

    expect(find.text('Rowing'), findsOneWidget);
    await tester.pump();
    // Photos de l'athlète : départ et arrivée, en fondu.
    expect(find.byType(ExercisePhotoDemo), findsOneWidget);
    expect(find.byType(FigureAnimation), findsNothing);
    expect(find.byType(Image), findsNWidgets(2));
    expect(find.byKey(ExercisePhotoDemo.pauseKey), findsOneWidget);
    await tester.tap(find.byKey(ExercisePhotoDemo.pauseKey));
    await tester.pump();
    expect(find.byTooltip("Lancer l'animation"), findsOneWidget);
    // Les silhouettes sont sous les photos : un défilement les affiche.
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
  });

  testWidgets('une vidéo de démonstration passe avant les photos', (
    tester,
  ) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.exerciseDetail('squat'));
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, exerciseVideoAsset('squat'));
    await tester.tap(find.byKey(ExercisePhotoDemo.pauseKey));
    await tester.pump();
    final still = tester.widget<Image>(find.byType(Image));
    expect((still.image as AssetImage).assetName, exerciseVideoStill('squat'));
    await tester.unmountApp();
  });

  testWidgets('animations réduites : départ et arrivée côte à côte', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.exerciseDetail('row'));
    await tester.pump();

    expect(find.text('Départ'), findsOneWidget);
    expect(find.text('Arrivée'), findsOneWidget);
    expect(find.byKey(ExercisePhotoDemo.pauseKey), findsNothing);
    await tester.unmountApp();
  });

  testWidgets('sans photo, le mannequin 2D montre l’exercice', (tester) async {
    final container = createTestContainer();
    await tester.openWithProfile(
      container,
      AppRoutes.exerciseDetail('bird_dog'),
    );
    await tester.pump();

    expect(find.byType(FigureAnimation), findsOneWidget);
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
