import 'package:arise/features/profile/domain/player_profile.dart';

/// Accès au profil du joueur, stocké sur le téléphone.
abstract interface class ProfileRepository {
  /// Émet le profil, ou `null` tant que le questionnaire n'est pas terminé.
  Stream<PlayerProfile?> watchProfile();

  Future<void> saveProfile(PlayerProfile profile);
}
