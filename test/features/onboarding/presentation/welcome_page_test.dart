import 'package:arise/features/onboarding/presentation/welcome_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('affiche le titre, l’accroche et l’accès au design system', (
    tester,
  ) async {
    await tester.pumpApp(const WelcomePage());

    expect(find.text('ARISE'), findsOneWidget);
    expect(
      find.text("Le royaume d'Arisia attend son prochain chasseur."),
      findsOneWidget,
    );
    expect(find.text('Voir le design system'), findsOneWidget);
  });
}
