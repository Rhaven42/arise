import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/profile/domain/profile_repository.dart';

/// Profil stocké dans la base locale Drift.
class DriftProfileRepository implements ProfileRepository {
  const DriftProfileRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<PlayerProfile?> watchProfile() {
    return _database.watchProfileJson().map(decodeProfile);
  }

  @override
  Future<void> saveProfile(PlayerProfile profile) {
    return _database.saveProfileJson(
      jsonEncode(profile.toJson()),
      updatedAt: DateTime.now(),
    );
  }

  /// Décode un profil enregistré ; `null` si absent.
  static PlayerProfile? decodeProfile(String? json) {
    if (json == null) return null;
    return PlayerProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }
}
