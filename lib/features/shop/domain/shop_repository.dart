import 'package:arise/features/shop/domain/shop_rules.dart';

/// Achats et teintures : débit des pièces et livraison en une seule
/// opération.
abstract interface class ShopRepository {
  /// Renvoie `null` si l'achat a réussi, sinon le motif du refus.
  Future<PurchaseIssue?> buy(ShopArticle article);

  /// Renvoie `null` si la teinture a réussi, sinon le motif du refus.
  Future<PurchaseIssue?> dye(String itemId, int color);
}
