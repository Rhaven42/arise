import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/titles/presentation/titles_page.dart';
import 'package:arise/features/titles/presentation/titles_providers.dart';
import 'package:arise/features/trials/domain/trials_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('équiper le titre d’un boss, puis son aura', (tester) async {
    final container = createTestContainer();
    await container
        .read(appDatabaseProvider)
        .saveTrialsJson(
          jsonEncode(
            const TrialsState(titles: ['title_rockGuardian', 'title_stormLord'])
                .toJson(),
          ),
          updatedAt: testNow,
        );
    await tester.openWithProfile(container, AppRoutes.titles);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Briseur de Rocher'), findsOneWidget);
    await tester.tap(find.byKey(TitlesPage.titleKey('title_rockGuardian')));
    await tester.pump(const Duration(milliseconds: 100));
    var view = await container.read(titlesViewProvider.future);
    expect(view.worn.equippedTitle, 'title_rockGuardian');

    // Le titre du Seigneur des Tempêtes débloque l'aura d'Orage.
    await tester.tap(find.byKey(TitlesPage.auraKey('aura_storm')));
    await tester.pump(const Duration(milliseconds: 100));
    view = await container.read(titlesViewProvider.future);
    expect(view.worn.equippedAura, 'aura_storm');
    expect(view.aura?.color, isNotNull);
    await tester.unmountApp();
  });
}
