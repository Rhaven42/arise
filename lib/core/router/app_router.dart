import 'package:arise/core/design_system/demo/design_system_demo_page.dart';
import 'package:arise/core/design_system/widgets/action_dock.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/router/route_guard.dart';
import 'package:arise/features/account/presentation/account_create_page.dart';
import 'package:arise/features/account/presentation/account_picker_page.dart';
import 'package:arise/features/account/presentation/account_providers.dart';
import 'package:arise/features/account/presentation/account_settings_page.dart';
import 'package:arise/features/achievements/presentation/achievements_page.dart';
import 'package:arise/features/achievements/presentation/hunter_panel.dart';
import 'package:arise/features/backup/presentation/backup_page.dart';
import 'package:arise/features/backup/presentation/restore_page.dart';
import 'package:arise/features/character_creation/presentation/character_creator_page.dart';
import 'package:arise/features/exercises/presentation/custom_exercise_editor_page.dart';
import 'package:arise/features/exercises/presentation/exercise_detail_page.dart';
import 'package:arise/features/exercises/presentation/exercise_list_page.dart';
import 'package:arise/features/health/presentation/health_page.dart';
import 'package:arise/features/inventory/presentation/inventory_page.dart';
import 'package:arise/features/muscle_analysis/presentation/muscle_analysis_page.dart';
import 'package:arise/features/onboarding/presentation/onboarding_page.dart';
import 'package:arise/features/onboarding/presentation/title_page.dart';
import 'package:arise/features/planning/presentation/planning_page.dart';
import 'package:arise/features/planning/presentation/program_editor_page.dart';
import 'package:arise/features/planning/presentation/programs_page.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/progression/presentation/hero_class_page.dart';
import 'package:arise/features/progression/presentation/stats_page.dart';
import 'package:arise/features/progression/presentation/system_home_page.dart';
import 'package:arise/features/quests/presentation/quest_panel.dart';
import 'package:arise/features/quests/presentation/quests_page.dart';
import 'package:arise/features/quests/presentation/quests_providers.dart';
import 'package:arise/features/settings/presentation/credits_page.dart';
import 'package:arise/features/settings/presentation/settings_page.dart';
import 'package:arise/features/shadows/presentation/shadows_page.dart';
import 'package:arise/features/shop/presentation/shop_page.dart';
import 'package:arise/features/titles/presentation/titles_page.dart';
import 'package:arise/features/trials/presentation/trial_page.dart';
import 'package:arise/features/workout_player/presentation/workout_page.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Convertit l'état asynchrone du profil pour le routeur. Un compte
/// verrouillé par son code PIN compte comme sans profil (retour au titre).
ProfileStatus profileStatusFrom(
  AsyncValue<PlayerProfile?> value, {
  bool locked = false,
}) {
  if (locked) return ProfileStatus.missing;
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
  bool locked() => ref.read(accountsControllerProvider).value?.locked ?? false;
  void refresh() => status.value = profileStatusFrom(
    ref.read(playerProfileProvider),
    locked: locked(),
  );
  ref
    ..onDispose(status.dispose)
    ..listen<AsyncValue<PlayerProfile?>>(
      playerProfileProvider,
      (_, _) => refresh(),
      fireImmediately: true,
    )
    ..listen<AsyncValue<AccountsView>>(
      accountsControllerProvider,
      (_, _) => refresh(),
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
        path: AppRoutes.accounts,
        builder: (_, _) => const AccountPickerPage(),
        routes: [
          GoRoute(
            path: AppRoutes.accountNewSegment,
            builder: (_, state) => AccountCreatePage(
              restore: state.uri.queryParameters['restore'] == '1',
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.systemHome,
        builder: (_, _) => const SystemHomePage(
          panels: [HunterPanel(), QuestPanel(), TrialPanel()],
          bottomBar: HomeDock(),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.settingsSegment,
            builder: (_, _) => const SettingsPage(),
            routes: [
              GoRoute(
                path: AppRoutes.backupSegment,
                builder: (_, _) => const BackupPage(),
              ),
              GoRoute(
                path: AppRoutes.creditsSegment,
                builder: (_, _) => const CreditsPage(),
              ),
              GoRoute(
                path: AppRoutes.accountSettingsSegment,
                builder: (_, _) => const AccountSettingsPage(),
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
            path: AppRoutes.healthSegment,
            builder: (_, _) => const HealthPage(),
          ),
          GoRoute(
            path: AppRoutes.achievementsSegment,
            builder: (_, _) => const AchievementsPage(),
          ),
          GoRoute(
            path: AppRoutes.titlesSegment,
            builder: (_, _) => const TitlesPage(),
          ),
          GoRoute(
            path: AppRoutes.shadowsSegment,
            builder: (_, _) => const ShadowsPage(),
          ),
          GoRoute(
            path: AppRoutes.questsSegment,
            builder: (_, _) => const QuestsPage(),
          ),
          GoRoute(
            path: AppRoutes.statsSegment,
            builder: (_, _) => const StatsPage(),
          ),
          GoRoute(
            path: AppRoutes.heroClassSegment,
            builder: (_, _) => const HeroClassPage(),
          ),
          GoRoute(
            path: AppRoutes.trialSegment,
            builder: (_, _) => const TrialPage(),
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

/// Barre d'action de la Fenêtre du Système : chaque emplacement mène à une
/// fonctionnalité (le routeur est seul à les assembler).
class HomeDock extends StatelessWidget {
  const HomeDock({super.key});

  static const trainKey = Key('dock-train');
  static const questsKey = Key('dock-quests');
  static const heroKey = Key('dock-hero');
  static const shopKey = Key('dock-shop');
  static const inventoryKey = Key('dock-inventory');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ActionDock(
      items: [
        DockItem(
          key: questsKey,
          icon: Icons.menu_book_outlined,
          label: l10n.dockQuests,
          onTap: () => context.go(AppRoutes.quests),
        ),
        DockItem(
          key: heroKey,
          icon: Icons.person_outline,
          label: l10n.dockHero,
          onTap: () => context.go(AppRoutes.character),
        ),
        DockItem(
          key: shopKey,
          icon: Icons.storefront_outlined,
          label: l10n.dockShop,
          onTap: () => context.go(AppRoutes.shop),
        ),
        DockItem(
          key: inventoryKey,
          icon: Icons.backpack_outlined,
          label: l10n.dockInventory,
          onTap: () => context.go(AppRoutes.inventory),
        ),
      ],
      center: DockItem(
        key: trainKey,
        icon: Icons.fitness_center,
        label: l10n.dockTrain,
        onTap: () => context.go(AppRoutes.workout(dailyQuestProgramId)),
      ),
    );
  }
}
