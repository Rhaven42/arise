import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/character_creation/domain/character_palette.dart';
import 'package:arise/features/character_creation/domain/character_rules.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:arise/features/character_creation/domain/name_rules.dart';
import 'package:arise/l10n/generated/app_localizations.dart';

String raceLabel(AppLocalizations l10n, CharacterRace race, CharacterSex sex) =>
    l10n.characterRaceName('${race.id}_${sex.name}');

String corpulenceLabel(AppLocalizations l10n, CharacterSheet sheet) =>
    l10n.characterCorpulenceStep(
      '${sheet.sex.name}_${sliderStep(sheet.corpulence)}',
    );

String musculatureLabel(AppLocalizations l10n, CharacterSheet sheet) =>
    l10n.characterMusculatureStep(
      '${sheet.sex.name}_${sliderStep(sheet.musculature)}',
    );

String hairStyleLabel(AppLocalizations l10n, int style) =>
    l10n.characterHairStyleName('h$style');

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
  corpulenceLabel(l10n, sheet),
  musculatureLabel(l10n, sheet),
  l10n.characterHeight(sheet.heightCm),
  hairStyleLabel(l10n, sheet.hairStyle),
].join(', ');

String presetLabel(AppLocalizations l10n, CharacterSex sex, String id) =>
    l10n.characterPresetName('${sex.name}_$id');

String faceStepLabel(AppLocalizations l10n, double value) =>
    l10n.characterFaceStep('s${sliderStep(value)}');

String eyebrowLabel(AppLocalizations l10n, int style) =>
    l10n.characterEyebrowName('b$style');

String beardLabel(AppLocalizations l10n, int style) =>
    l10n.characterBeardName('b$style');

String makeupLabel(AppLocalizations l10n, int style) =>
    l10n.characterMakeupName('m$style');
