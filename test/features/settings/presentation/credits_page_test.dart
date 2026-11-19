import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/settings/domain/credits.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  test('chaque ressource a un auteur et une source', () {
    for (final credit in [...artCredits, ...otherCredits]) {
      expect(credit.work, isNotEmpty);
      expect(credit.author, isNotEmpty);
      expect(credit.source, isNotEmpty);
    }
    expect(artCredits.single.license, CreditLicense.generated);
  });

  testWidgets('les crédits citent l’origine des illustrations et les polices', (
    tester,
  ) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.credits);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Crédits'), findsOneWidget);
    expect(
      find.text(
        'Héros, coiffures, tenues et armes en pixel art — Hero Protocol, '
        'généré avec SpriteCook',
      ),
      findsOneWidget,
    );
    expect(find.text('Cinzel — Natanael Gama'), findsOneWidget);
    await tester.unmountApp();
  });
}
