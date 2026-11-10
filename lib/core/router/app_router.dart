import 'package:arise/core/design_system/demo/design_system_demo_page.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/router/route_guard.dart';
import 'package:arise/features/backup/presentation/backup_page.dart';
import 'package:arise/features/backup/presentation/restore_page.dart';
import 'package:arise/features/character_creation/presentation/character_creator_page.dart';
import 'package:arise/features/exercises/presentation/custom_exercise_editor_page.dart';
import 'package:arise/features/exercises/presentation/exercise_detail_page.dart';
import 'package:arise/features/exercises/presentation/exercise_list_page.dart';
import 'package:arise/features/inventory/presentation/inventory_page.dart';
import 'package:arise/features/muscle_analysis/presentation/muscle_analysis_page.dart';
import 'package:arise/features/onboarding/presentation/onboarding_page.dart';
import 'package:arise/features/onboarding/presentation/title_page.dart';
import 'package:arise/features/planning/presentation/planning_page.dart';
import 'package:arise/features/planning/presentation/program_editor_page.dart';
import 'package:arise/features/planning/presentation/programs_page.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/progression/presentation/system_home_page.dart';
import 'package:arise/features/settings/presentation/settings_page.dart';
import 'package:arise/features/shop/presentation/shop_page.dart';
import 'package:arise/features/workout_player/presentation/workout_page.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Convertit l'état asynchrone du profil pour le routeur.
ProfileStatus profileStatusFrom(AsyncValue<PlayerProfile?> value) {
  return switch (value) {
    AsyncData(value: final profile) =>
      profile == null ? ProfileStatus.missing : ProfileStatus.ready,
    AsyncError() => ProfileStatus.missing,
    _ => ProfileStatus.unknown,
  };
}

/// Routeur de l'application, réévalué à chaque changement du profil.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final status = ValueNotifier<ProfileStatus>(ProfileStatus.unknown);
  ref
    ..onDispose(status.dispose)
    ..listen<AsyncValue<PlayerProfile?>>(
      playerProfileProvider,
      (_, next) => status.value = profileStatusFrom(next),
      fireImmediately: true,
    );

  final router = GoRouter(
    initialLocation: AppRoutes.title,
    refreshListenable: status,
    redirect: (_, state) =>
        resolveRedirect(location: state.matchedLocation, status: status.value),
    routes: [
      GoRoute(
        path: AppRoutes.title,
        builder: (_, _) => const TitlePage(),
        routes: [
          GoRoute(
            path: AppRoutes.designSystemSegment,
            builder: (_, _) => const DesignSystemDemoPage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingPage(),
      ),
      GoRoute(path: AppRoutes.restore, builder: (_, _) => const RestorePage()),
      GoRoute(
        path: AppRoutes.systemHome,
        builder: (_, _) => const SystemHomePage(),
        routes: [
          GoRoute(
            path: AppRoutes.settingsSegment,
            builder: (_, _) => const SettingsPage(),
            routes: [
              GoRoute(
                path: AppRoutes.backupSegment,
                builder: (_, _) => const BackupPage(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.exercisesSegment,
            builder: (_, _) => const ExerciseListPage(),
            routes: [
              GoRoute(
                path: AppRoutes.customExerciseNewSegment,
                builder: (_, _) => const CustomExerciseEditorPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    ExerciseDetailPage(exerciseId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => CustomExerciseEditorPage(
                      exerciseId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.programsSegment,
            builder: (_, _) => const ProgramsPage(),
            routes: [
              GoRoute(
                path: AppRoutes.programNewSegment,
                builder: (_, _) => const ProgramEditorPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    ProgramEditorPage(programId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.analysisSegment,
            builder: (_, _) => const MuscleAnalysisPage(),
          ),
          GoRoute(
            path: AppRoutes.characterSegment,
            builder: (_, _) => const CharacterCreatorPage(),
          ),
          GoRoute(
            path: AppRoutes.shopSegment,
            builder: (_, _) => const ShopPage(),
          ),
          GoRoute(
            path: AppRoutes.inventorySegment,
            builder: (_, _) => const InventoryPage(),
          ),
          GoRoute(
            path: AppRoutes.planningSegment,
            builder: (_, _) => const PlanningPage(),
          ),
          GoRoute(
            path: '${AppRoutes.workoutSegment}/:programId',
            builder: (_, state) =>
                WorkoutPage(programId: state.pathParameters['programId']!),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
