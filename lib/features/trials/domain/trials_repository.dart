import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/trials/domain/trials_state.dart';

/// Stockage de l'historique des épreuves.
abstract interface class TrialsRepository {
  Future<TrialsState?> read();

  Stream<TrialsState?> watch();

  /// Enregistre ensemble l'issue d'une épreuve : historique, progression et,
  /// après une victoire, l'inventaire avec l'objet exclusif.
  Future<void> saveOutcome({
    required TrialsState trials,
    required ProgressionState progression,
    Inventory? inventory,
  });

  /// Inventaire actuel (pour y ajouter la récompense).
  Future<Inventory> readInventory();
}
