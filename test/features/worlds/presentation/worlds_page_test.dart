import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/world_palette.dart';
import 'package:arise/features/achievements/domain/achievements_state.dart';
import 'package:arise/features/achievements/presentation/achievements_providers.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/worlds/domain/world.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  tearDown(() => WorldPalette.active = WorldPalette.medieval);

  testWidgets('univers verrouillés, puis entrée dans la Magie', (tester) async {
    final container = createTestContainer();
    await tester.openWithProfile(container, AppRoutes.worlds);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Univers'), findsWidgets);
    expect(find.text('Univers actif'), findsOneWidget);
    expect(
      find.text('Se débloque avec le haut fait « L’Appel des Arcanes ».'),
      findsOneWidget,
    );
    expect(find.text('Entrer dans cet univers'), findsNothing);

    // Haut fait obtenu : la Magie s'ouvre.
    await container
        .read(achievementsRepositoryProvider)
        .save(AchievementsState(unlocked: {'realm_arcane': testNow}));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Entrer dans cet univers'), findsOneWidget);

    await tester.tap(find.text('Entrer dans cet univers'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(playerProfileProvider).value?.world, World.arcane);
    // Ambiance de l'univers : palette et police des titres.
    expect(WorldPalette.active, WorldPalette.arcane);
    expect(WorldPalette.active.displayFont, 'Metamorphous');
    await tester.unmountApp();
  });
}
