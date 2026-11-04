import 'package:arise/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Captures d'écran de référence, prises sur un émulateur Android
// (workflow « screenshots »).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures des écrans de la phase 0', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    await binding.takeScreenshot('01_accueil');

    await tester.tap(find.text('Voir le design system'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02_design_system_haut');

    final list = find.byType(ListView);
    for (var i = 3; i <= 7; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('0${i}_design_system');
    }
  });
}
