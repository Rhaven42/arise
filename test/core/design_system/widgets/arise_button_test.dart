import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('déclenche l’action au toucher', (tester) async {
    var taps = 0;
    await tester.pumpApp(
      Center(
        child: AriseButton(label: 'Valider', onPressed: () => taps++),
      ),
    );

    await tester.tap(find.text('Valider'));
    expect(taps, 1);
  });

  testWidgets('offre une cible tactile d’au moins 48 px', (tester) async {
    await tester.pumpApp(
      Center(
        child: AriseButton(
          label: 'Plus tard',
          variant: AriseButtonVariant.secondary,
          icon: Icons.close,
          onPressed: () {},
        ),
      ),
    );

    final size = tester.getSize(find.byType(OutlinedButton));
    expect(size.height, greaterThanOrEqualTo(AriseSpacing.minTouchTarget));
  });

  testWidgets('est désactivé sans action', (tester) async {
    await tester.pumpApp(
      const Center(child: AriseButton(label: 'Indisponible', onPressed: null)),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
