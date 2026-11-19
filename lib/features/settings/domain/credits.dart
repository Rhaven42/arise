/// Origine ou licence d'une ressource incluse dans l'application.
enum CreditLicense {
  /// Images générées pour Hero Protocol avec un outil (propriété du projet).
  generated,
  ccBy,
  cc0,
  publicDomain,
  mit,
  ofl,
}

/// Ressource créditée (nom de l'œuvre et auteur tels que publiés).
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

/// Illustrations du héros (corps, coiffures, tenues, armes) : générées pour
/// le projet avec SpriteCook (docs/ASSETS.md).
const List<Credit> artCredits = [
  Credit(
    work: 'Héros, coiffures, tenues et armes en pixel art',
    author: 'Hero Protocol, généré avec SpriteCook',
    license: CreditLicense.generated,
    source: 'spritecook.ai',
  ),
];

/// Polices et autres ressources libres.
const List<Credit> otherCredits = [
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
