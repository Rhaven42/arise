import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/progression/data/drift_progression_repository.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/hero_class.dart';
import 'package:arise/features/progression/domain/progression_repository.dart';
import 'package:arise/features/progression/domain/progression_rules.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';
import 'package:arise/features/workout_player/presentation/workout_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'progression_providers.g.dart';

@Riverpod(keepAlive: true)
ProgressionRepository progressionRepository(Ref ref) =>
    DriftProgressionRepository(
      ref.watch(appDatabaseProvider),
      ref.watch(clockProvider),
    );

/// Progression affichée et dernier bilan de la bascule quotidienne.
class ProgressionView {
  const ProgressionView({required this.state, this.report});

  final ProgressionState state;

  /// Bilan des jours écoulés depuis la dernière ouverture, à annoncer.
  final RolloverReport? report;
}

/// Progression du joueur : chargée, mise à jour au fil des jours écoulés
/// (bascule quotidienne) et à chaque séance.
@Riverpod(keepAlive: true)
class ProgressionController extends _$ProgressionController {
  @override
  Future<ProgressionView> build() async {
    // Recharge après une restauration ou un effacement des données.
    final profile = await ref.watch(playerProfileProvider.future);
    final now = _now();
    final repository = ref.read(progressionRepositoryProvider);
    var state = await repository.read();
    if (profile == null) {
      return ProgressionView(
        state: state ?? ProgressionState.initial(CivilDate.ofLocal(now)),
      );
    }
    if (state == null) {
      // Première ouverture avec la progression : on rejoue l'XP des séances
      // déjà enregistrées, sans pénalité rétroactive.
      final sessions = await ref
          .read(completedSessionRepositoryProvider)
          .readAll();
      state = replaySessionXp(
        ProgressionState.initial(CivilDate.ofLocal(now)),
        [
          for (final session in sessions.reversed)
            (xp: session.xpEarned, xpByStat: session.xpByStat),
        ],
      );
      await repository.save(state);
    }
    final rollover = runDailyRollover(
      state,
      now: now,
      restDays: profile.restDays,
    );
    if (rollover.state != state) await repository.save(rollover.state);
    return ProgressionView(
      state: rollover.state,
      report: rollover.report.isEmpty ? null : rollover.report,
    );
  }

  DateTime _now() => ref.read(clockProvider)();

  Future<ProgressionView> _current() async => state.value ?? await future;

  Future<Set<int>> _restDays() async =>
      (await ref.read(playerProfileProvider.future))?.restDays ?? const {};

  Future<void> _save(ProgressionState next, {RolloverReport? report}) async {
    await ref.read(progressionRepositoryProvider).save(next);
    state = AsyncData(ProgressionView(state: next, report: report));
  }

  /// Applique une séance enregistrée : bascule des jours écoulés, puis XP,
  /// série, coffres et quête de pénalité.
  Future<SessionProgress> recordSession(
    CompletedSession session, {
    Map<StatId, double> statMultipliers = const {},
  }) async {
    final current = await _current();
    final now = _now();
    final restDays = await _restDays();
    final rollover = runDailyRollover(
      current.state,
      now: now,
      restDays: restDays,
    );
    final progress = applySession(
      rollover.state,
      baseXp: session.xpEarned,
      baseXpByStat: session.xpByStat,
      baseXpByDifficulty: session.xpByDifficulty,
      completed: session.completed,
      now: now,
      restDays: restDays,
      statMultipliers: statMultipliers,
    );
    await _save(
      progress.state,
      report: rollover.report.isEmpty ? current.report : rollover.report,
    );
    return progress;
  }

  /// Verse de l'XP de stat gagnée hors séance (santé du téléphone).
  Future<void> addStatXp(Map<StatId, int> xp) async {
    if (xp.isEmpty) return;
    final current = await _current();
    await _save(grantStatXp(current.state, xp), report: current.report);
  }

  /// Place un point de stat libre.
  Future<void> allocate(StatId stat) async {
    final current = await _current();
    final next = allocateStatPoint(current.state, stat);
    if (next != null) await _save(next, report: current.report);
  }

  /// Choisit ou change de classe (rang C, une fois par mois). Renvoie le
  /// motif du refus, ou `null` si le choix est enregistré.
  Future<ClassChoiceIssue?> chooseHeroClass(HeroClass heroClass) async {
    final current = await _current();
    final now = _now();
    final issue = classChoiceIssue(current.state, heroClass, now: now);
    if (issue != null) return issue;
    final next = chooseClass(current.state, heroClass, now: now);
    if (next != null) await _save(next, report: current.report);
    return null;
  }

  /// Active le mode maladie ou blessure pour [days] jours.
  Future<void> startSickMode(int days) async {
    final current = await _current();
    await _save(
      setSickMode(current.state, now: _now(), days: days),
      report: current.report,
    );
  }

  Future<void> stopSickMode() async {
    final current = await _current();
    await _save(
      endSickMode(current.state, now: _now()),
      report: current.report,
    );
  }

  /// Adopte une progression déjà enregistrée par une autre règle du jeu
  /// (quête terminée, épreuve), dans la même transaction que sa cause.
  Future<void> adopt(ProgressionState next) async {
    final current = await _current();
    state = AsyncData(ProgressionView(state: next, report: current.report));
  }

  /// Le message du Système a été lu.
  Future<void> dismissReport() async {
    final current = await _current();
    state = AsyncData(ProgressionView(state: current.state));
  }
}
