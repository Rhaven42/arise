import 'package:arise/features/onboarding/presentation/onboarding_page.dart';
import 'package:arise/features/onboarding/presentation/title_page.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('un nouveau joueur peut commencer ou restaurer', (tester) async {
    await tester.pumpAriseApp(createTestContainer());

    expect(find.byKey(TitlePage.logoKey), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Hero Protocol',
      ),
      findsOneWidget,
    );
    expect(find.text("Commencer l'aventure"), findsOneWidget);
    expect(find.text('Restaurer une sauvegarde'), findsOneWidget);
    expect(find.text('Continuer'), findsNothing);

    await tester.tap(find.text("Commencer l'aventure"));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);
    await tester.unmountApp();
  });

  testWidgets('un joueur éveillé voit « Continuer »', (tester) async {
    final container = createTestContainer();
    await container.read(profileRepositoryProvider).saveProfile(sampleProfile);
    await tester.pumpAriseApp(container);

    expect(find.text('Continuer'), findsOneWidget);
    expect(find.text("Commencer l'aventure"), findsNothing);
    await tester.unmountApp();
  });
}
