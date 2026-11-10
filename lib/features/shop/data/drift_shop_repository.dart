import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/shop/domain/shop_repository.dart';
import 'package:arise/features/shop/domain/shop_rules.dart';

/// Achats enregistrés dans la base locale, dans une transaction.
class DriftShopRepository implements ShopRepository {
  const DriftShopRepository(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  @override
  Future<PurchaseIssue?> buy(ShopArticle article) => _apply(
    (balance, inventory) =>
        purchase(balance: balance, inventory: inventory, article: article),
  );

  @override
  Future<PurchaseIssue?> dye(String itemId, int color) => _apply(
    (balance, inventory) => dyeItem(
      balance: balance,
      inventory: inventory,
      itemId: itemId,
      color: color,
    ),
  );

  Future<PurchaseIssue?> _apply(
    PurchaseResult Function(int balance, Inventory inventory) rule,
  ) => _database.updateProgressionAndInventory<PurchaseIssue?>(
    (progressionJson, inventoryJson) async {
      final progression = progressionJson == null
          ? null
          : ProgressionState.fromJson(
              jsonDecode(progressionJson) as Map<String, dynamic>,
            );
      final inventory = inventoryJson == null
          ? const Inventory()
          : sanitizeInventory(
              Inventory.fromJson(
                jsonDecode(inventoryJson) as Map<String, dynamic>,
              ),
            );
      final result = rule(progression?.coins ?? 0, inventory);
      final paid = result.issue == null && progression != null;
      return (
        progression: paid
            ? jsonEncode(progression.copyWith(coins: result.balance).toJson())
            : null,
        inventory: jsonEncode(result.inventory.toJson()),
        result: result.issue,
      );
    },
    updatedAt: _clock(),
  );
}
