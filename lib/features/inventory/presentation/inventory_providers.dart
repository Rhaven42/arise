import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/inventory/data/drift_inventory_repository.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/inventory/domain/inventory_repository.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'inventory_providers.g.dart';

@Riverpod(keepAlive: true)
InventoryRepository inventoryRepository(Ref ref) => DriftInventoryRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(clockProvider),
);

/// Inventaire du joueur, mis à jour à chaque achat ou changement de tenue.
@riverpod
Stream<Inventory> inventory(Ref ref) =>
    ref.watch(inventoryRepositoryProvider).watch();

/// Porter ou retirer un objet.
@riverpod
class InventoryController extends _$InventoryController {
  @override
  void build() {}

  /// Renvoie le motif du refus, ou `null` si l'objet est porté.
  Future<EquipIssue?> equipItem(String itemId) async {
    final repository = ref.read(inventoryRepositoryProvider);
    final result = equip(await repository.read(), itemId);
    if (result.issue == null) await repository.save(result.inventory);
    return result.issue;
  }

  Future<void> unequipSlot(EquipmentSlot slot) async {
    final repository = ref.read(inventoryRepositoryProvider);
    await repository.save(unequip(await repository.read(), slot));
  }
}
