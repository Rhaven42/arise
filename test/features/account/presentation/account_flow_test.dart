import 'package:arise/core/router/app_router.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/account/presentation/account_create_page.dart';
import 'package:arise/features/account/presentation/account_picker_page.dart';
import 'package:arise/features/account/presentation/account_settings_page.dart';
import 'package:arise/features/onboarding/presentation/onboarding_page.dart';
import 'package:arise/features/progression/presentation/system_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_accounts.dart';
import '../../../helpers/test_app.dart';

void main() {
  testWidgets('premier lancement : création du compte puis Éveil', (
    tester,
  ) async {
    final accounts = FakeAccountRepository();
    final container = createTestContainer(accounts: accounts);
    await tester.pumpAriseApp(container);

    await tester.tap(find.text("Commencer l'aventure"));
    await tester.pumpAndSettle();
    expect(find.byType(AccountCreatePage), findsOneWidget);

    // Pseudo manquant.
    await tester.tap(find.byKey(AccountCreatePage.createKey));
    await tester.pumpAndSettle();
    expect(find.text('Choisis un pseudo.'), findsOneWidget);

    // Codes PIN différents.
    await tester.enterText(find.byKey(AccountCreatePage.nameKey), 'Aelin');
    await tester.tap(find.byKey(AccountCreatePage.pinToggleKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(AccountCreatePage.pinKey), '1234');
    await tester.enterText(find.byKey(AccountCreatePage.pinConfirmKey), '4321');
    await tester.tap(find.byKey(AccountCreatePage.createKey));
    await tester.pumpAndSettle();
    expect(find.text('Les deux codes ne sont pas identiques.'), findsOneWidget);

    await tester.enterText(find.byKey(AccountCreatePage.pinConfirmKey), '1234');
    await tester.tap(find.byKey(AccountCreatePage.createKey));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);

    final created = (await accounts.readAll()).single;
    expect(created.name, 'Aelin');
    expect(created.pinHash, 'sel:1234');
    expect(accounts.activeId, created.id);
    await tester.unmountApp();
  });

  testWidgets('un compte protégé demande son code PIN', (tester) async {
    final locked = testAccount().copyWith(pinSalt: 'sel', pinHash: 'sel:1234');
    final container = createTestContainer(
      accounts: FakeAccountRepository(accounts: [locked], activeId: 'test'),
    );
    await tester.openWithProfile(container, AppRoutes.systemHome);
    // Verrouillé : les écrans du jeu renvoient au titre.
    expect(find.byType(SystemHomePage), findsNothing);
    expect(find.text('Compte : Testeur'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pin-field')), '0000');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(find.text('Code PIN incorrect.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pin-field')), '1234');
    await tester.tap(find.text('Valider'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SystemHomePage), findsOneWidget);
    await tester.unmountApp();
  });

  testWidgets('changer de compte depuis l’écran titre', (tester) async {
    final accounts = FakeAccountRepository(
      accounts: [
        testAccount(id: 'a', name: 'Aelin'),
        testAccount(id: 'b', name: 'Rowan'),
      ],
      activeId: 'a',
    );
    final container = createTestContainer(accounts: accounts);
    await tester.pumpAriseApp(container);
    expect(find.text('Compte : Aelin'), findsOneWidget);

    await tester.tap(find.text('Changer de compte'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountPickerPage), findsOneWidget);
    await tester.tap(find.byKey(AccountPickerPage.accountKey('b')));
    await tester.pumpAndSettle();

    expect(find.text('Compte : Rowan'), findsOneWidget);
    expect(accounts.activeId, 'b');
    await tester.unmountApp();
  });

  testWidgets('renommer puis supprimer le compte', (tester) async {
    final accounts = FakeAccountRepository(
      accounts: [testAccount()],
      activeId: 'test',
    );
    final storage = FakeAccountStorage(existing: {'arise_test'});
    final container = createTestContainer(
      accounts: accounts,
      accountStorage: storage,
    );
    await tester.openWithProfile(container, AppRoutes.accountSettings);
    expect(find.byType(AccountSettingsPage), findsOneWidget);

    await tester.enterText(find.byKey(AccountSettingsPage.nameKey), 'Aelin');
    await tester.tap(find.text('Enregistrer le pseudo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect((await accounts.readAll()).single.name, 'Aelin');

    await tester.tap(find.byKey(AccountSettingsPage.deleteKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Supprimer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(await accounts.readAll(), isEmpty);
    expect(storage.deleted, ['arise_test']);
    expect(
      container.read(appRouterProvider).state.matchedLocation,
      AppRoutes.title,
    );
    await tester.unmountApp();
  });
}
