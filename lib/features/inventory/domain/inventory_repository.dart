import 'package:arise/features/inventory/domain/inventory.dart';

/// Stockage de l'inventaire du joueur.
abstract interface class InventoryRepository {
  /// Inventaire enregistré (vide s'il n'a jamais été créé).
  Future<Inventory> read();

  Stream<Inventory> watch();

  Future<void> save(Inventory inventory);
}
