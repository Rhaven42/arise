import 'package:arise/features/character_creation/domain/name_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepte un nom de 3 à 16 caractères', () {
    expect(checkName('Aelin'), isNull);
    expect(checkName('Éowyn-Lune'), isNull);
    expect(checkName("D'Arvel"), isNull);
    expect(checkName('  Kai  '), isNull);
  });

  test('refuse un nom trop court ou trop long', () {
    expect(checkName('Al'), NameIssue.tooShort);
    expect(checkName('   '), NameIssue.tooShort);
    expect(checkName('Abcdefghijklmnopq'), NameIssue.tooLong);
  });

  test('refuse les chiffres et les symboles', () {
    expect(checkName('Kai99'), NameIssue.invalidCharacters);
    expect(checkName('Kai_Lune'), NameIssue.invalidCharacters);
    expect(checkName('-Kai'), NameIssue.invalidCharacters);
  });

  test('filtre les insultes, même déguisées', () {
    expect(checkName('Connard'), NameIssue.forbidden);
    expect(checkName('C0nn4rd'), NameIssue.forbidden);
    expect(checkName('Grosse Merde'), NameIssue.forbidden);
    expect(checkName('Enculé'), NameIssue.forbidden);
    expect(checkName('pd'), NameIssue.tooShort);
    expect(checkName('P.D'), NameIssue.forbidden);
  });

  test('ne bloque pas un mot court contenu dans un vrai nom', () {
    // « pd » et « fdp » ne sont refusés que seuls.
    expect(checkName('Spade'), isNull);
    expect(normalizeName('Élé-0nore'), 'eleonore');
  });
}
