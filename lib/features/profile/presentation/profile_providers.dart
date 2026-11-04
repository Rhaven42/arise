import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/profile/data/drift_profile_repository.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/profile/domain/profile_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_providers.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) {
  return DriftProfileRepository(ref.watch(appDatabaseProvider));
}

/// Profil du joueur (ou `null` avant la fin du questionnaire).
@Riverpod(keepAlive: true)
Stream<PlayerProfile?> playerProfile(Ref ref) {
  return ref.watch(profileRepositoryProvider).watchProfile();
}
