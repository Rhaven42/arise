import 'package:arise/app.dart';
import 'package:arise/core/database/accounts_database.dart';
import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/licenses.dart';
import 'package:arise/features/account/data/account_bootstrap.dart';
import 'package:arise/features/account/data/account_files.dart';
import 'package:arise/features/account/data/drift_account_repository.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  // Le compte actif est lu avant l'interface : ses données s'ouvrent
  // directement (la base d'avant les comptes devient le premier compte).
  final accounts = AccountsDatabase(driftDatabase(name: 'accounts'));
  final snapshot = await loadAccounts(
    DriftAccountRepository(accounts),
    const FileAccountStorage(),
    now: DateTime.now(),
  );
  runApp(
    ProviderScope(
      overrides: [
        accountsDatabaseProvider.overrideWithValue(accounts),
        initialDatabaseNameProvider.overrideWithValue(
          snapshot.active?.databaseName,
        ),
      ],
      child: const AriseApp(),
    ),
  );
}
