import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/worlds/domain/world.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'worlds_providers.g.dart';

/// Univers actif du joueur (Médiéval tant que le profil n'est pas lu).
@riverpod
World activeWorld(Ref ref) =>
    ref.watch(playerProfileProvider).value?.world ?? World.medieval;

/// Change d'univers : seulement vers un univers ouvert par son haut fait.
@Riverpod(keepAlive: true)
class WorldsController extends _$WorldsController {
  @override
  void build() {}

  /// Active [world] ; renvoie `false` s'il est encore verrouillé.
  Future<bool> activate(World world, Set<String> unlockedAchievements) async {
    if (!isWorldUnlocked(world, unlockedAchievements)) return false;
    final profile = await ref.read(playerProfileProvider.future);
    if (profile == null) return false;
    await ref
        .read(profileRepositoryProvider)
        .saveProfile(profile.copyWith(world: world));
    return true;
  }
}
