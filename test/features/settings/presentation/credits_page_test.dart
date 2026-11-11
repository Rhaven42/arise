import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/settings/domain/credits.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  test('chaque ressource CC BY a un auteur et une source', () {
    expect(ccByCredits, isNotEmpty);
    for (final credit in ccByCredits) {
      expect(credit.license, CreditLicense.ccBy);
      expect(credit.author, isNotEmpty);
      expect(credit.source, startsWith('makehumancommunity.org/node/'));
    }
  });

  testWidgets('les crédits citent les auteurs des ressources CC BY', (
    tester,
  ) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.credits);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Crédits'), findsOneWidget);
    expect(find.text('Lace up blouse — punkduck'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('three.js — three.js authors'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('three.js — three.js authors'), findsOneWidget);
    await tester.unmountApp();
  });
}
