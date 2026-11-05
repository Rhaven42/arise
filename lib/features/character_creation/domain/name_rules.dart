import 'package:arise/core/config/game_config.dart';

/// Raison du refus d'un nom de personnage.
enum NameIssue { tooShort, tooLong, invalidCharacters, forbidden }

/// Mots refusés (recherchés dans le nom normalisé : minuscules, sans
/// accents, chiffres « leet » convertis, sans espaces ni ponctuation).
const List<String> forbiddenNameParts = [
  'connard',
  'connasse',
  'salope',
  'salaud',
  'encule',
  'enfoire',
  'putain',
  'pute',
  'batard',
  'merde',
  'nique',
  'fdp',
  'pd',
  'tapette',
  'negre',
  'bougnoul',
  'youpin',
  'nazi',
  'hitler',
  'fuck',
  'shit',
  'bitch',
  'whore',
  'slut',
  'cunt',
  'nigger',
  'nigga',
  'faggot',
  'retard',
];

/// Mots courts refusés seulement quand ils forment tout le nom.
const List<String> _forbiddenWholeNames = ['pd', 'fdp'];

final RegExp _allowed = RegExp(r"^[\p{L}][\p{L}' -]*$", unicode: true);

const Map<String, String> _accents = {
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'á': 'a',
  'ã': 'a',
  'å': 'a',
  'ç': 'c',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'î': 'i',
  'ï': 'i',
  'í': 'i',
  'ì': 'i',
  'ô': 'o',
  'ö': 'o',
  'ó': 'o',
  'ò': 'o',
  'õ': 'o',
  'û': 'u',
  'ü': 'u',
  'ú': 'u',
  'ù': 'u',
  'ÿ': 'y',
  'ñ': 'n',
  'œ': 'oe',
  'æ': 'ae',
};

const Map<String, String> _leet = {
  '0': 'o',
  '1': 'i',
  '3': 'e',
  '4': 'a',
  '5': 's',
  '7': 't',
  '@': 'a',
  r'$': 's',
};

/// Nom réduit à ses lettres de base, pour le filtre.
String normalizeName(String name) {
  final buffer = StringBuffer();
  for (final rune in name.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final mapped = _accents[char] ?? _leet[char] ?? char;
    if (RegExp('[a-z]').hasMatch(mapped)) buffer.write(mapped);
  }
  return buffer.toString();
}

/// Vérifie un nom : longueur, caractères autorisés et filtre anti-insultes.
/// Renvoie `null` si le nom est accepté.
NameIssue? checkName(String raw, {CharacterConfig? config}) {
  final c = config ?? gameConfig.character;
  final name = raw.trim();
  final length = name.runes.length;
  if (length < c.usernameMinLength) return NameIssue.tooShort;
  if (length > c.usernameMaxLength) return NameIssue.tooLong;
  final normalized = normalizeName(name);
  for (final word in forbiddenNameParts) {
    if (_forbiddenWholeNames.contains(word)) {
      if (normalized == word) return NameIssue.forbidden;
    } else if (normalized.contains(word)) {
      return NameIssue.forbidden;
    }
  }
  if (!_allowed.hasMatch(name)) return NameIssue.invalidCharacters;
  return null;
}
