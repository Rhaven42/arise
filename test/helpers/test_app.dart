import 'dart:io';
import 'dart:math';

import 'package:arise/app.dart';
import 'package:arise/core/anatomy/body_shapes.dart';
import 'package:arise/core/anatomy/body_shapes_provider.dart';
import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/audio/music.dart';
import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/router/app_router.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/account/presentation/account_providers.dart';
import 'package:arise/features/avatar/presentation/character_renderer.dart';
import 'package:arise/features/backup/presentation/backup_controller.dart';
import 'package:arise/features/character_creation/presentation/character_providers.dart';
import 'package:arise/features/exercises/data/asset_exercise_catalog_repository.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/presentation/animation/figure_animation.dart';
import 'package:arise/features/exercises/presentation/animation/figure_motion.dart';
import 'package:arise/features/exercises/presentation/exercise_providers.dart';
import 'package:arise/features/planning/presentation/planning_providers.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/workout_player/presentation/workout_cues.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_accounts.dart';
import 'fake_backup_file_gateway.dart';
import 'fake_character_renderer.dart';
import 'fake_music_player.dart';
import 'fake_reminder_scheduler.dart';
import 'fake_workout_cues.dart';

/// Date fixe utilisée par les tests.
final testNow = DateTime.utc(2026, 11, 4, 9);

/// Profil complet prêt à l'emploi.
final sampleProfile = PlayerProfile(
  goal: FitnessGoal.strength,
  level: FitnessLevel.beginner,
  equipment: const {Equipment.dumbbells},
  restDays: const {DateTime.wednesday, DateTime.sunday},
  healthConsent: false,
  createdAt: testNow,
);

/// Contenus embarqués lus directement sur le disque (évite les chargements
/// asynchrones d'assets dans les tests de widgets).
final List<Exercise> testCatalog = AssetExerciseCatalogRepository.decodeCatalog(
  File(AssetExerciseCatalogRepository.assetPath).readAsStringSync(),
);

final Map<String, FigureMotion> testMotions = decodeMotions(
  File(motionsAsset).readAsStringSync(),
);
final Map<BodyView, BodyShapes> testBodyShapes = {
  for (final view in BodyView.values)
    view: BodyShapesParser.parse(
      File(bodyShapeAssets[view]!).readAsStringSync(),
      view,
    ),
};

/// Base en mémoire, fermée automatiquement à la fin du test.
AppDatabase createTestDatabase() {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  return database;
}

/// Conteneur Riverpod isolé : base en mémoire, horloge fixe, faux fichiers.
ProviderContainer createTestContainer({
  AppDatabase? database,
  FakeBackupFileGateway? files,
  FakeReminderScheduler? reminders,
  DateTime Function()? clock,
  FakeWorkoutCues? cues,
  FakeCharacterRenderer? renderer,
  FakeSnapshotSharer? sharer,
  FakeMusicPlayer? music,
  FakeAccountRepository? accounts,
  FakeAccountStorage? accountStorage,
}) {
  return ProviderContainer.test(
    overrides: [
      appDatabaseProvider.overrideWithValue(database ?? createTestDatabase()),
      // Un compte sans code PIN est ouvert, sauf registre fourni.
      accountRepositoryProvider.overrideWithValue(
        accounts ??
            FakeAccountRepository(accounts: [testAccount()], activeId: 'test'),
      ),
      accountStorageProvider.overrideWithValue(
        accountStorage ?? FakeAccountStorage(),
      ),
      pinHasherProvider.overrideWithValue(FakePinHasher()),
      clockProvider.overrideWithValue(clock ?? () => testNow),
      workoutCuesProvider.overrideWithValue(cues ?? FakeWorkoutCues()),
      backupFileGatewayProvider.overrideWithValue(
        files ?? FakeBackupFileGateway(),
      ),
      reminderSchedulerProvider.overrideWithValue(
        reminders ?? FakeReminderScheduler(),
      ),
      characterRendererProvider.overrideWithValue(
        renderer ?? FakeCharacterRenderer(),
      ),
      snapshotSharerProvider.overrideWithValue(sharer ?? FakeSnapshotSharer()),
      characterRandomProvider.overrideWithValue(Random(7)),
      musicPlayerProvider.overrideWithValue(music ?? FakeMusicPlayer()),
      exerciseCatalogProvider.overrideWith((_) async => testCatalog),
      figureMotionsProvider.overrideWith((_) async => testMotions),
      bodyShapesProvider.overrideWith((_) async => testBodyShapes),
    ],
  );
}

extension PumpAriseApp on WidgetTester {
  /// Lance l'application complète sur un conteneur de test.
  Future<void> pumpAriseApp(ProviderContainer container) async {
    await pumpWidget(
      UncontrolledProviderScope(container: container, child: const AriseApp()),
    );
    await pumpAndSettle();
  }

  /// Lance l'application avec un profil déjà créé et ouvre [location].
  ///
  /// N'attend pas la fin des animations (certaines tournent en boucle).
  Future<void> openWithProfile(
    ProviderContainer container,
    String location,
  ) async {
    await container.read(profileRepositoryProvider).saveProfile(sampleProfile);
    await pumpWidget(
      UncontrolledProviderScope(container: container, child: const AriseApp()),
    );
    await pump();
    await pump();
    container.read(appRouterProvider).go(location);
    await pump();
    await pump(const Duration(milliseconds: 300));
  }

  /// Démonte l'application pour libérer les flux de la base avant sa
  /// fermeture.
  Future<void> unmountApp() async {
    await pumpWidget(const SizedBox.shrink());
    await pump(const Duration(milliseconds: 10));
  }
}
