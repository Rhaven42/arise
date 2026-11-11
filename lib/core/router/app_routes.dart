/// Chemins des écrans de l'application.
abstract final class AppRoutes {
  static const title = '/';
  static const designSystemSegment = 'design-system';
  static const String designSystem = '/$designSystemSegment';
  static const onboarding = '/onboarding';
  static const restore = '/restore';
  static const systemHome = '/system';
  static const settingsSegment = 'settings';
  static const String settings = '$systemHome/$settingsSegment';
  static const backupSegment = 'backup';
  static const String backup = '$settings/$backupSegment';

  static const exercisesSegment = 'exercises';
  static const String exercises = '$systemHome/$exercisesSegment';
  static const customExerciseNewSegment = 'custom-new';
  static const String customExerciseNew =
      '$exercises/$customExerciseNewSegment';
  static String exerciseDetail(String id) => '$exercises/$id';
  static String customExerciseEdit(String id) => '$exercises/$id/edit';

  static const programsSegment = 'programs';
  static const String programs = '$systemHome/$programsSegment';
  static const programNewSegment = 'new';
  static const String programNew = '$programs/$programNewSegment';
  static String programEdit(String id) => '$programs/$id';

  static const analysisSegment = 'analysis';
  static const String analysis = '$systemHome/$analysisSegment';

  static const characterSegment = 'character';
  static const String character = '$systemHome/$characterSegment';

  static const shopSegment = 'shop';
  static const String shop = '$systemHome/$shopSegment';

  static const inventorySegment = 'inventory';
  static const String inventory = '$systemHome/$inventorySegment';

  static const workoutSegment = 'workout';
  static String workout(String programId) =>
      '$systemHome/$workoutSegment/$programId';

  static const questsSegment = 'quests';
  static const String quests = '$systemHome/$questsSegment';

  static const heroClassSegment = 'class';
  static const String heroClass = '$systemHome/$heroClassSegment';

  static const trialSegment = 'trial';
  static const String trial = '$systemHome/$trialSegment';

  static const planningSegment = 'planning';
  static const String planning = '$systemHome/$planningSegment';

  /// Vrai pour les écrans réservés à un joueur ayant terminé l'Éveil.
  static bool requiresProfile(String location) =>
      location == systemHome || location.startsWith('$systemHome/');
}
