import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

String itemLabel(AppLocalizations l10n, EquipmentItem item) =>
    l10n.itemName(item.id);

String slotLabel(AppLocalizations l10n, EquipmentSlot slot) =>
    l10n.equipmentSlotName(slot.name);

String rarityLabel(AppLocalizations l10n, Rarity rarity) =>
    l10n.rarityName(rarity.name);

/// Couleur d'une rareté (toujours doublée du libellé et de [rarityIcon]).
Color rarityColor(Rarity rarity) => switch (rarity) {
  Rarity.common => AriseColors.rarityCommon,
  Rarity.rare => AriseColors.rarityRare,
  Rarity.epic => AriseColors.rarityEpic,
  Rarity.legendary => AriseColors.rarityLegendary,
  Rarity.mythic => AriseColors.rarityMythic,
};

/// Icône propre à chaque rareté, lisible sans les couleurs.
IconData rarityIcon(Rarity rarity) => switch (rarity) {
  Rarity.common => Icons.circle_outlined,
  Rarity.rare => Icons.change_history,
  Rarity.epic => Icons.square_outlined,
  Rarity.legendary => Icons.star_outline,
  Rarity.mythic => Icons.auto_awesome,
};

IconData slotIcon(EquipmentSlot slot) => switch (slot) {
  EquipmentSlot.head => Icons.face_retouching_natural,
  EquipmentSlot.shoulders => Icons.shield_outlined,
  EquipmentSlot.chest => Icons.checkroom,
  EquipmentSlot.hands => Icons.back_hand_outlined,
  EquipmentSlot.belt => Icons.horizontal_rule,
  EquipmentSlot.legs => Icons.straighten,
  EquipmentSlot.feet => Icons.hiking,
  EquipmentSlot.back => Icons.flag_outlined,
  EquipmentSlot.weapon => Icons.colorize,
};
