/// Licence d'une ressource tierce incluse dans l'application.
enum CreditLicense { ccBy, cc0, mit, ofl }

/// Ressource tierce créditée (nom de l'œuvre et auteur tels que publiés).
class Credit {
  const Credit({
    required this.work,
    required this.author,
    required this.license,
    required this.source,
  });

  final String work;
  final String author;
  final CreditLicense license;

  /// Adresse de la page d'origine (affichée en texte, sans lien réseau).
  final String source;
}

/// Ressources sous licence CC BY : leur mention est obligatoire (docs/ASSETS.md).
const List<Credit> ccByCredits = [
  Credit(
    work: 'Lace up blouse',
    author: 'punkduck',
    license: CreditLicense.ccBy,
    source: 'makehumancommunity.org/node/1775',
  ),
  Credit(
    work: 'Alpha 7 long hair',
    author: 'punkduck',
    license: CreditLicense.ccBy,
    source: 'makehumancommunity.org/node/482',
  ),
  Credit(
    work: 'Alpha 7 curly hair',
    author: 'punkduck',
    license: CreditLicense.ccBy,
    source: 'makehumancommunity.org/node/480',
  ),
  Credit(
    work: 'Grump hair',
    author: 'Elvaerwyn',
    license: CreditLicense.ccBy,
    source: 'makehumancommunity.org/node/2796',
  ),
  Credit(
    work: 'Braid bun',
    author: 'Elvaerwyn',
    license: CreditLicense.ccBy,
    source: 'makehumancommunity.org/node/2177',
  ),
  Credit(
    work: 'Wavy bob',
    author: 'Elvaerwyn',
    license: CreditLicense.ccBy,
    source: 'makehumancommunity.org/node/1551',
  ),
  Credit(
    work: 'Scruffy beard 1',
    author: 'Elvaerwyn',
    license: CreditLicense.ccBy,
    source: 'makehumancommunity.org/node/2611',
  ),
  Credit(
    work: 'Full beard',
    author: 'grinsegold',
    license: CreditLicense.ccBy,
    source: 'makehumancommunity.org/node/188',
  ),
  Credit(
    work: 'Dal moustache',
    author: 'culturalibre',
    license: CreditLicense.ccBy,
    source: 'makehumancommunity.org/node/2872',
  ),
];

/// Autres ressources (mention non obligatoire, faite par courtoisie).
const List<Credit> otherCredits = [
  Credit(
    work: 'MakeHuman (corps, peaux, yeux, sourcils, vêtements et cheveux CC0)',
    author: 'MakeHuman Community',
    license: CreditLicense.cc0,
    source: 'makehumancommunity.org',
  ),
  Credit(
    work: 'three.js',
    author: 'three.js authors',
    license: CreditLicense.mit,
    source: 'threejs.org',
  ),
  Credit(
    work: 'Cinzel',
    author: 'Natanael Gama',
    license: CreditLicense.ofl,
    source: 'fonts.google.com/specimen/Cinzel',
  ),
  Credit(
    work: 'IM Fell English',
    author: 'Igino Marini',
    license: CreditLicense.ofl,
    source: 'fonts.google.com/specimen/IM+Fell+English',
  ),
];
