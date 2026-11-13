/// Licence d'une ressource tierce incluse dans l'application.
enum CreditLicense { ccBy, cc0, publicDomain, mit, ofl }

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
  Credit(
    work: 'Male boho top 1',
    author: 'Elvaerwyn',
    license: CreditLicense.ccBy,
    source: 'makehumancommunity.org/node/1808',
  ),
  Credit(
    work: 'Medieval boots',
    author: 'punkduck',
    license: CreditLicense.ccBy,
    source: 'makehumancommunity.org/node/1381',
  ),
  Credit(
    work: 'Tight leather boots',
    author: 'madmanny',
    license: CreditLicense.ccBy,
    source: 'makehumancommunity.org/node/1448',
  ),
  Credit(
    work: 'Modular Medieval Armor',
    author: 'Jhon Panesso',
    license: CreditLicense.ccBy,
    source: 'sketchfab.com/3d-models/f4156f249ea34c19afb57519f6b032af',
  ),
  Credit(
    work: 'Medieval Knight Armor (Low-poly / Rigged)',
    author: 'INKXO',
    license: CreditLicense.ccBy,
    source: 'sketchfab.com/3d-models/428913948904425e8daec81eea9aa287',
  ),
  Credit(
    work: 'Old king armor',
    author: 'Pedro B. Goulart',
    license: CreditLicense.ccBy,
    source: 'sketchfab.com/3d-models/f5a4479d211e49d49937b55fd9478e85',
  ),
  Credit(
    work: 'free knight armor 2k',
    author: 'DEYMAR',
    license: CreditLicense.ccBy,
    source: 'sketchfab.com/3d-models/8009434a1776469ea8cb3225c2d63dfb',
  ),
  Credit(
    work: 'Female Noble Knight Armor',
    author: 'Meast',
    license: CreditLicense.ccBy,
    source: 'sketchfab.com/3d-models/5b40c2e4b40d48378d595268d2db69bb',
  ),
  Credit(
    work: 'Leather Armor',
    author: 'Blueprint Games',
    license: CreditLicense.ccBy,
    source: 'sketchfab.com/3d-models/0693e6cbc82b47f7a8c08a7bb87ae72b',
  ),
  Credit(
    work: 'Fantasy scaled armor',
    author: 'nordwar',
    license: CreditLicense.ccBy,
    source: 'sketchfab.com/3d-models/c592ef6e41b346bca2e7de9109388276',
  ),
  Credit(
    work: 'Viking lamellar armor',
    author: 'nordwar',
    license: CreditLicense.ccBy,
    source: 'sketchfab.com/3d-models/297c2536534c4045aa0be028d10d39d4',
  ),
  Credit(
    work: 'Elven Ranger',
    author: 'BiscuitEater',
    license: CreditLicense.ccBy,
    source: 'sketchfab.com/3d-models/daed59994fd340bc8f7e1d9bb30d6cdf',
  ),
  Credit(
    work: 'The Knight',
    author: 'klava88',
    license: CreditLicense.ccBy,
    source: 'sketchfab.com/3d-models/6c619f8c392a469eac9fddcce9a3aa55',
  ),
  Credit(
    work: 'samurai armor set female',
    author: 'stasbelyk13',
    license: CreditLicense.ccBy,
    source: 'sketchfab.com/3d-models/a4fc24bfb52b4625945797ad01d0f8a0',
  ),
  Credit(
    work: 'Medieval Guard',
    author: 'Taylor',
    license: CreditLicense.ccBy,
    source: 'sketchfab.com/3d-models/ca548172f0984660bc4213b9404284fa',
  ),
  Credit(
    work: 'Cloak / Robe',
    author: 'xdragonxallix',
    license: CreditLicense.ccBy,
    source: 'sketchfab.com/3d-models/13532c211daf4d1b8852276eea74d845',
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
    work: 'Matières cuir, maille, acier, or et tissu',
    author: 'ambientCG',
    license: CreditLicense.cc0,
    source: 'ambientcg.com',
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
