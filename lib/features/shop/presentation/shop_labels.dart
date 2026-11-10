import 'package:arise/features/inventory/presentation/inventory_labels.dart';
import 'package:arise/features/shop/domain/shop_rules.dart';
import 'package:arise/l10n/generated/app_localizations.dart';

/// Libellé d'un article de la boutique.
String articleLabel(AppLocalizations l10n, ShopArticle article) =>
    switch (article) {
      ItemArticle(:final item) => itemLabel(l10n, item),
      HairStyleArticle(:final style) => l10n.shopHairStyleArticle(
        l10n.characterHairStyleName('h$style'),
      ),
    };

/// Message d'un refus d'achat ou de teinture.
String purchaseIssueLabel(AppLocalizations l10n, PurchaseIssue issue) =>
    switch (issue) {
      PurchaseIssue.alreadyOwned => l10n.shopAlreadyOwned,
      PurchaseIssue.notEnoughCoins => l10n.shopNotEnough,
      PurchaseIssue.notForSale => l10n.shopNotForSale,
      PurchaseIssue.notOwned => l10n.shopNotOwned,
    };
