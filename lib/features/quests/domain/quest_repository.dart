import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/quests/domain/daily_quest.dart';
import 'package:arise/features/quests/domain/quest_board.dart';

/// Stockage de la quête quotidienne.
abstract interface class QuestRepository {
  Future<DailyQuest?> read();

  Future<void> save(DailyQuest quest);

  /// Enregistre la quête et la progression ensemble (récompense versée).
  Future<void> saveWithProgression(
    DailyQuest quest,
    ProgressionState progression,
  );

  /// Quêtes de la semaine, donjon et événements (vide au départ).
  Future<QuestBoard> readBoard();

  /// Inventaire actuel (butin du donjon).
  Future<Inventory> readInventory();

  /// Enregistre ensemble, dans une seule transaction, les quêtes et ce
  /// qu'elles rapportent (`null` = inchangé).
  Future<void> saveOutcome({
    DailyQuest? quest,
    QuestBoard? board,
    ProgressionState? progression,
    Inventory? inventory,
  });
}
