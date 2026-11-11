import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/achievements/presentation/achievements_providers.dart';
import 'package:arise/features/titles/data/drift_titles_repository.dart';
import 'package:arise/features/titles/domain/title_rules.dart';
import 'package:arise/features/titles/domain/title_rules.dart' as rules;
import 'package:arise/features/titles/domain/titles_repository.dart';
import 'package:arise/features/titles/domain/titles_state.dart';
import 'package:arise/features/trials/presentation/trials_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'titles_providers.g.dart';

@Riverpod(keepAlive: true)
TitlesRepository titlesRepository(Ref ref) => DriftTitlesRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(clockProvider),
);

/// Titres et auras obtenus, et ce que le joueur porte.
class TitlesView {
  const TitlesView({
    required this.earned,
    required this.auras,
    required this.worn,
  });

  final List<String> earned;
  final List<AuraDefinition> auras;
  final TitlesState worn;

  /// Aura portée, ou `null`.
  AuraDefinition? get aura => auraById(worn.equippedAura);
}

@Riverpod(keepAlive: true)
Stream<TitlesState> titlesState(Ref ref) =>
    ref.watch(titlesRepositoryProvider).watch();

@Riverpod(keepAlive: true)
Future<TitlesView> titlesView(Ref ref) async {
  final earned = earnedTitles(
    trials: await ref.watch(trialsStateProvider.future),
    achievements: await ref.watch(achievementsStateProvider.future),
  );
  return TitlesView(
    earned: earned,
    auras: earnedAuras(earned),
    worn: wornTitles(
      await ref.watch(titlesStateProvider.future),
      earned: earned,
    ),
  );
}

/// Choix du titre et de l'aura.
@Riverpod(keepAlive: true)
class TitlesController extends _$TitlesController {
  @override
  void build() {}

  Future<void> equipTitle(String? titleId) async {
    final view = await ref.read(titlesViewProvider.future);
    final next = rules.equipTitle(view.worn, titleId, earned: view.earned);
    if (next != null) await ref.read(titlesRepositoryProvider).save(next);
  }

  Future<void> equipAura(String? auraId) async {
    final view = await ref.read(titlesViewProvider.future);
    final next = rules.equipAura(view.worn, auraId, earned: view.earned);
    if (next != null) await ref.read(titlesRepositoryProvider).save(next);
  }
}
