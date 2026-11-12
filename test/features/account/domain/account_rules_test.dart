import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/account/domain/account_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_accounts.dart';

void main() {
  final existing = [testAccount(id: 'a', name: 'Aelin')];

  test('un pseudo doit être non vide, court et libre', () {
    expect(accountNameIssue('  ', existing), AccountNameIssue.empty);
    expect(
      accountNameIssue('x' * (gameConfig.account.nameMaxLength + 1), existing),
      AccountNameIssue.tooLong,
    );
    expect(accountNameIssue(' aelin ', existing), AccountNameIssue.taken);
    expect(accountNameIssue('Aelin', existing, exceptId: 'a'), isNull);
    expect(accountNameIssue('Rowan', existing), isNull);
  });

  test('le code PIN compte exactement le nombre de chiffres prévu', () {
    final digits = gameConfig.account.pinLength;
    expect(isValidPin('1' * digits), isTrue);
    expect(isValidPin('1' * (digits - 1)), isFalse);
    expect(isValidPin('${'1' * (digits - 1)}a'), isFalse);
  });

  test('nombre maximal de comptes', () {
    final full = [
      for (var i = 0; i < gameConfig.account.maxAccounts; i++)
        testAccount(id: '$i', name: 'J$i'),
    ];
    expect(canCreateAccount(full), isFalse);
    expect(canCreateAccount(full.skip(1)), isTrue);
  });

  test('vérification du code PIN', () {
    final hasher = FakePinHasher();
    final open = testAccount();
    expect(pinMatches(open, '', hasher), isTrue);
    final locked = open.copyWith(pinSalt: 'sel', pinHash: 'sel:1234');
    expect(locked.hasPin, isTrue);
    expect(pinMatches(locked, '1234', hasher), isTrue);
    expect(pinMatches(locked, '0000', hasher), isFalse);
  });

  test('nom affiché, base dédiée et tri par utilisation', () {
    expect(testAccount(name: '').displayName('Sans nom'), 'Sans nom');
    expect(databaseNameFor('abc'), 'arise_abc');
    final old = testAccount(id: 'old');
    final recent = old.copyWith(id: 'new', lastUsedAt: DateTime.utc(2027));
    expect(sortedByLastUse([old, recent]).first.id, 'new');
  });
}
