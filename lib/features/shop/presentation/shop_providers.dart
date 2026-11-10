import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/features/shop/data/drift_shop_repository.dart';
import 'package:arise/features/shop/domain/shop_repository.dart';
import 'package:arise/features/shop/domain/shop_rules.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shop_providers.g.dart';

@Riverpod(keepAlive: true)
ShopRepository shopRepository(Ref ref) => DriftShopRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(clockProvider),
);

/// Achats et teintures ; la bourse affichée est rechargée après chaque
/// dépense.
@Riverpod(keepAlive: true)
class ShopController extends _$ShopController {
  @override
  void build() {}

  Future<PurchaseIssue?> buy(ShopArticle article) async {
    final issue = await ref.read(shopRepositoryProvider).buy(article);
    if (issue == null) ref.invalidate(progressionControllerProvider);
    return issue;
  }

  Future<PurchaseIssue?> dye(String itemId, int color) async {
    final issue = await ref.read(shopRepositoryProvider).dye(itemId, color);
    if (issue == null) ref.invalidate(progressionControllerProvider);
    return issue;
  }
}
