import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory.freezed.dart';
part 'inventory.g.dart';

/// Ce que possède le joueur : objets, coiffures débloquées, objets portés
/// et teintures. Enregistré en JSON sur le téléphone.
@freezed
abstract class Inventory with _$Inventory {
  const factory Inventory({
    /// Objets achetés (identifiants du catalogue).
    @Default(<String>[]) List<String> owned,

    /// Coiffures achetées (numéros).
    @Default(<int>[]) List<int> hairStyles,

    /// Objet porté par emplacement.
    @Default(<EquipmentSlot, String>{}) Map<EquipmentSlot, String> equipped,

    /// Teinture choisie par objet (couleur ARGB).
    @Default(<String, int>{}) Map<String, int> dyes,
  }) = _Inventory;

  factory Inventory.fromJson(Map<String, dynamic> json) =>
      _$InventoryFromJson(json);
}
