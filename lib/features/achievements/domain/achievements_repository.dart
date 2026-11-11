import 'package:arise/features/achievements/domain/achievements_state.dart';

/// Stockage local de l'état « achievements ».
abstract interface class AchievementsRepository {
  Future<AchievementsState> read();

  Stream<AchievementsState> watch();

  Future<void> save(AchievementsState state);
}
