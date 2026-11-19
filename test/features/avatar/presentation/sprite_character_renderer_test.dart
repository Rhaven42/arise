import 'dart:io';
import 'dart:ui' as ui;

import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/domain/character_scene.dart';
import 'package:arise/features/avatar/presentation/character_renderer.dart';
import 'package:arise/features/avatar/presentation/sprite_character_renderer.dart';
import 'package:arise/features/character_creation/domain/character_rules.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('les calques réels se décodent et s’assemblent', (tester) async {
    await tester.runAsync(() async {
      final atlas = await SpriteAtlas.load();
      // La peau garde son marquage après décodage du PNG.
      final body = await atlas.image('bodies/demon_female.png');
      var skin = 0;
      for (var i = 3; i < body.pixels.length; i += 4) {
        if (body.pixels[i] == atlas.meta.skinAlpha) skin++;
      }
      expect(skin, greaterThan(500));

      final appearance = CharacterAppearance.of(
        defaultSheet(
          sex: CharacterSex.male,
          race: CharacterRace.dwarf,
        ).copyWith(hairStyle: 7, beardStyle: 2),
        loadout: const Loadout(
          outfitId: 'north_lamellar',
          outfitTint: 0xFF7A1E1E,
          weaponId: 'hammer_runic',
        ),
      );
      final image = await atlas.render(appearance);
      expect(image.width, atlas.meta.width);
      expect(image.height, atlas.meta.height);
      final bytes = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      var opaque = 0;
      for (var i = 3; i < bytes!.lengthInBytes; i += 4) {
        if (bytes.getUint8(i) > 0) opaque++;
      }
      // Corps, tenue, barbe, coiffure et marteau : une silhouette pleine.
      expect(opaque, greaterThan(3000));
      image.dispose();
    });
  });

  testWidgets('le rendu affiche le personnage et fournit une capture', (
    tester,
  ) async {
    const renderer = SpriteCharacterRenderer();
    final snapshots = CharacterSnapshotController();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SizedBox(
          width: 300,
          height: 500,
          child: renderer.build(
            appearance: CharacterAppearance.of(
              defaultSheet(race: CharacterRace.goblin),
            ).adorned(auraColor: 0xFFFFD700, shadows: [0, 1]),
            scene: const CharacterScene(focus: SceneFocus.face),
            snapshots: snapshots,
          ),
        ),
      ),
    );
    expect(find.text('Le Système façonne ton héros…'), findsOneWidget);
    await tester.runAsync(() async {
      for (
        var i = 0;
        i < 50 && find.byType(CustomPaint).evaluate().length < 2;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    expect(find.text('Le Système façonne ton héros…'), findsNothing);
    final png = await tester.runAsync(snapshots.capture);
    expect(png, isNotNull);
    expect(png!.sublist(1, 4), 'PNG'.codeUnits);
    if (Platform.environment['ARISE_SPRITE_SHOT'] case final path?) {
      File(path).writeAsBytesSync(png);
    }
  });
}
