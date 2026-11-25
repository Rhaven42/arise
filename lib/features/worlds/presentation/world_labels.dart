import 'package:arise/features/worlds/domain/world.dart';
import 'package:arise/l10n/generated/app_localizations.dart';

String worldLabel(AppLocalizations l10n, World world) =>
    l10n.worldName(world.name);

String materialLabel(AppLocalizations l10n, EquipmentMaterial material) =>
    l10n.materialName(material.name);
