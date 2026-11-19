import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/character_creation/domain/character_palette.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:arise/features/character_creation/domain/name_rules.dart';
import 'package:arise/l10n/generated/app_localizations.dart';

String raceLabel(AppLocalizations l10n, CharacterRace race, CharacterSex sex) =>
    l10n.characterRaceName('${race.id}_${sex.name}');

/// Nom d'une coiffure (0 = crâne rasé), selon le sexe.
String hairStyleLabel(AppLocalizations l10n, CharacterSex sex, int style) =>
    l10n.characterHairStyleName(style == 0 ? 'none' : '${sex.name[0]}$style');

String skinLabel(AppLocalizations l10n, int color, CharacterRace race) {
  final swatch = swatchOf(skinsFor(race), color);
  return swatch == null ? '' : l10n.characterSkinName(swatch.id);
}

String hairColorLabel(AppLocalizations l10n, int color) {
  final swatch = swatchOf(hairColors, color);
  return swatch == null ? '' : l10n.characterHairColorName(swatch.id);
}

String? nameIssueLabel(AppLocalizations l10n, NameIssue? issue) {
  final c = gameConfig.character;
  return switch (issue) {
    null => null,
    NameIssue.tooShort => l10n.characterNameTooShort(c.usernameMinLength),
    NameIssue.tooLong => l10n.characterNameTooLong(c.usernameMaxLength),
    NameIssue.invalidCharacters => l10n.characterNameInvalid,
    NameIssue.forbidden => l10n.characterNameForbidden,
  };
}

/// Description lisible du personnage (lecteur d'écran).
String describeCharacter(AppLocalizations l10n, CharacterSheet sheet) => [
  raceLabel(l10n, sheet.race, sheet.sex),
  skinLabel(l10n, sheet.skinColor, sheet.race),
  hairStyleLabel(l10n, sheet.sex, sheet.hairStyle),
  hairColorLabel(l10n, sheet.hairColor),
  if (sheet.sex == CharacterSex.male && sheet.beardStyle > 0)
    beardLabel(l10n, sheet.beardStyle),
].where((s) => s.isNotEmpty).join(', ');

String beardLabel(AppLocalizations l10n, int style) =>
    l10n.characterBeardName('b$style');
