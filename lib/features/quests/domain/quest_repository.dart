import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/quests/domain/daily_quest.dart';

/// Stockage de la quête quotidienne.
abstract interface class QuestRepository {
  Future<DailyQuest?> read();

  Future<void> save(DailyQuest quest);

  /// Enregistre la quête et la progression ensemble (récompense versée).
  Future<void> saveWithProgression(
    DailyQuest quest,
    ProgressionState progression,
  );
}
