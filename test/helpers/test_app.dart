import 'package:arise/app.dart';
import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/backup/presentation/backup_controller.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backup_file_gateway.dart';

/// Date fixe utilisée par les tests.
final testNow = DateTime.utc(2026, 11, 4, 9);

/// Profil complet prêt à l'emploi.
final sampleProfile = PlayerProfile(
  goal: FitnessGoal.strength,
  level: FitnessLevel.beginner,
  equipment: const {Equipment.dumbbells},
  restDays: const {DateTime.wednesday, DateTime.sunday},
  healthConsent: false,
  createdAt: testNow,
);

/// Base en mémoire, fermée automatiquement à la fin du test.
AppDatabase createTestDatabase() {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  return database;
}

/// Conteneur Riverpod isolé : base en mémoire, horloge fixe, faux fichiers.
ProviderContainer createTestContainer({
  AppDatabase? database,
  FakeBackupFileGateway? files,
}) {
  return ProviderContainer.test(
    overrides: [
      appDatabaseProvider.overrideWithValue(database ?? createTestDatabase()),
      clockProvider.overrideWithValue(() => testNow),
      backupFileGatewayProvider.overrideWithValue(
        files ?? FakeBackupFileGateway(),
      ),
    ],
  );
}

extension PumpAriseApp on WidgetTester {
  /// Lance l'application complète sur un conteneur de test.
  Future<void> pumpAriseApp(ProviderContainer container) async {
    await pumpWidget(
      UncontrolledProviderScope(container: container, child: const AriseApp()),
    );
    await pumpAndSettle();
  }

  /// Démonte l'application pour libérer les flux de la base avant sa
  /// fermeture.
  Future<void> unmountApp() async {
    await pumpWidget(const SizedBox.shrink());
    await pump(const Duration(milliseconds: 10));
  }
}
