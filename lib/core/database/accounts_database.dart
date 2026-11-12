import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'accounts_database.g.dart';

/// Comptes locaux du téléphone.
@DataClassName('AccountRow')
class Accounts extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  /// Base Drift du compte (fichier `<nom>.sqlite`).
  TextColumn get databaseName => text()();

  TextColumn get pinHash => text().nullable()();

  TextColumn get pinSalt => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get lastUsedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Réglages du registre (compte actif).
@DataClassName('AccountSettingRow')
class AccountSettings extends Table {
  TextColumn get settingKey => text()();

  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {settingKey};
}

/// Registre des comptes, séparé des données de jeu (une base par compte).
@DriftDatabase(tables: [Accounts, AccountSettings])
class AccountsDatabase extends _$AccountsDatabase {
  AccountsDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

/// Registre des comptes de l'application.
@Riverpod(keepAlive: true)
AccountsDatabase accountsDatabase(Ref ref) {
  final database = AccountsDatabase(driftDatabase(name: 'accounts'));
  ref.onDispose(() => unawaited(database.close()));
  return database;
}
