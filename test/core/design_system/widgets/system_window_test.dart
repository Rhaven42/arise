import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/system_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('affiche l’en-tête, le titre, le contenu et les actions', (
    tester,
  ) async {
    var accepted = false;
    await tester.pumpApp(
      SystemWindow(
        header: 'Système',
        title: 'Quête quotidienne',
        actions: [
          AriseButton(label: 'Accepter', onPressed: () => accepted = true),
        ],
        child: const Text('30 pompes'),
      ),
    );

    expect(find.text('SYSTÈME'), findsOneWidget);
    expect(find.text('Quête quotidienne'), findsOneWidget);
    expect(find.text('30 pompes'), findsOneWidget);

    await tester.tap(find.text('Accepter'));
    expect(accepted, isTrue);
  });
}
