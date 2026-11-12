import 'package:arise/core/router/app_router.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/features/backup/domain/backup_codec.dart';
import 'package:arise/features/onboarding/presentation/title_page.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/progression/presentation/system_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_backup_file_gateway.dart';
import '../../../helpers/test_app.dart';

Future<ProviderContainer> _openBackupPage(
  WidgetTester tester,
  FakeBackupFileGateway files,
) async {
  final container = createTestContainer(files: files);
  await container.read(profileRepositoryProvider).saveProfile(sampleProfile);
  await tester.pumpAriseApp(container);
  container.read(appRouterProvider).go(AppRoutes.backup);
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('l’export partage un fichier et le confirme', (tester) async {
    final files = FakeBackupFileGateway();
    await _openBackupPage(tester, files);

    await tester.tap(find.text('Exporter une sauvegarde'));
    await tester.pumpAndSettle();

    expect(files.shared, hasLength(1));
    expect(find.text('Sauvegarde exportée.'), findsOneWidget);
    await tester.unmountApp();
  });

  testWidgets('un fichier étranger est refusé avec un message clair', (
    tester,
  ) async {
    final files = FakeBackupFileGateway(fileToPick: '{"format": "autre"}');
    await _openBackupPage(tester, files);

    await tester.tap(find.text('Restaurer une sauvegarde'));
    await tester.pumpAndSettle();

    expect(
      find.text("Ce fichier n'est pas une sauvegarde Hero Protocol."),
      findsOneWidget,
    );
    await tester.unmountApp();
  });

  testWidgets('l’effacement demande confirmation puis ramène au titre', (
    tester,
  ) async {
    final container = await _openBackupPage(tester, FakeBackupFileGateway());

    await tester.ensureVisible(find.text('Effacer toutes mes données'));
    await tester.tap(find.text('Effacer toutes mes données'));
    await tester.pumpAndSettle();
    expect(find.text('Tout effacer ?'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(container.read(playerProfileProvider).value, isNotNull);

    await tester.tap(find.text('Effacer toutes mes données'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Effacer'));
    await tester.pumpAndSettle();

    expect(find.byType(TitlePage), findsOneWidget);
    expect(container.read(playerProfileProvider).value, isNull);
    await tester.unmountApp();
  });

  testWidgets('depuis le titre, une sauvegarde restaure la partie', (
    tester,
  ) async {
    final backup = BackupCodec.encode(
      BackupCodec.create(exportedAt: testNow, profile: sampleProfile),
    );
    final container = createTestContainer(
      files: FakeBackupFileGateway(fileToPick: backup),
    );
    await tester.pumpAriseApp(container);

    await tester.tap(find.text('Restaurer une sauvegarde'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.folder_open));
    await tester.pumpAndSettle();
    expect(find.text('Restaurer cette sauvegarde ?'), findsOneWidget);
    await tester.tap(find.text('Restaurer'));
    await tester.pumpAndSettle();

    expect(find.byType(SystemHomePage), findsOneWidget);
    await tester.unmountApp();
  });
}
