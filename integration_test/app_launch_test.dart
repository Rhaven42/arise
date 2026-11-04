import 'package:arise/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Vérifie sur un vrai appareil (émulateur Android en CI) que l'application
// démarre : initialisation de Firebase, base locale, routeur et accueil.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('l’application démarre sur l’accueil', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('ARISE'), findsOneWidget);
    expect(find.text('Voir le design system'), findsOneWidget);

    await tester.tap(find.text('Voir le design system'));
    await tester.pumpAndSettle();
    expect(find.text('Design system'), findsOneWidget);
  });
}
