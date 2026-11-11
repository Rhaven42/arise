import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/features/quests/domain/quest_board.dart';
import 'package:arise/features/shadows/data/drift_shadows_repository.dart';
import 'package:arise/features/shadows/domain/shadow_rules.dart';
import 'package:arise/features/shadows/domain/shadows_repository.dart';
import 'package:arise/features/shadows/domain/shadows_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shadows_providers.g.dart';

@Riverpod(keepAlive: true)
ShadowsRepository shadowsRepository(Ref ref) => DriftShadowsRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(clockProvider),
);

/// Armée d'Ombres.
@Riverpod(keepAlive: true)
Stream<ShadowsState> shadowsState(Ref ref) =>
    ref.watch(shadowsRepositoryProvider).watch();

/// Extraction et activation des Ombres.
@Riverpod(keepAlive: true)
class ShadowsController extends _$ShadowsController {
  @override
  void build() {}

  ShadowsRepository get _repository => ref.read(shadowsRepositoryProvider);

  Future<void> _save(ShadowsState before, ShadowsState after) async {
    if (after != before) await _repository.save(after);
  }

  /// Propose les Ombres des boss vaincus à partir du rang B (y compris les
  /// victoires d'avant la phase 9).
  Future<void> offerFromBosses() async {
    final progression = await ref.read(progressionRepositoryProvider).read();
    if (progression == null) return;
    final state = await _repository.read();
    await _save(state, offerBossShadows(state, progression.defeatedBosses));
  }

  /// Propose l'Ombre d'un donjon terminé.
  Future<void> offerFromDungeon(DungeonRun run) async {
    final progression = await ref.read(progressionRepositoryProvider).read();
    if (progression == null) return;
    final state = await _repository.read();
    await _save(
      state,
      offerDungeonShadow(state, run, playerRank: progression.rank),
    );
  }

  /// Extrait l'Ombre en attente [key].
  Future<Shadow?> extract(String key) async {
    final progression = await ref.read(progressionRepositoryProvider).read();
    final state = await _repository.read();
    final next = extractShadow(
      state,
      key,
      now: ref.read(clockProvider)(),
      heroClass: progression?.heroClass,
    );
    if (next == null) return null;
    await _repository.save(next);
    return next.shadows.last;
  }

  /// Active ou met au repos une Ombre.
  Future<ShadowIssue?> toggle(String id) async {
    final progression = await ref.read(progressionRepositoryProvider).read();
    final state = await _repository.read();
    final result = toggleShadow(state, id, heroClass: progression?.heroClass);
    await _save(state, result.state);
    return result.issue;
  }

  /// Multiplicateurs d'XP par stat des Ombres actives.
  Future<Map<StatId, double>> statMultipliers() async {
    final progression = await ref.read(progressionRepositoryProvider).read();
    return shadowStatMultipliers(
      await _repository.read(),
      heroClass: progression?.heroClass,
    );
  }
}
