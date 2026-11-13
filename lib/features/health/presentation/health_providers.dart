import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/health/data/drift_health_repository.dart';
import 'package:arise/features/health/data/platform_health_source.dart';
import 'package:arise/features/health/domain/health_log.dart';
import 'package:arise/features/health/domain/health_repository.dart';
import 'package:arise/features/health/domain/health_rules.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/features/workout_player/presentation/workout_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'health_providers.g.dart';

@Riverpod(keepAlive: true)
HealthRepository healthRepository(Ref ref) => DriftHealthRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(clockProvider),
);

/// Source des données du téléphone (remplacée dans les tests).
@Riverpod(keepAlive: true)
HealthSource healthSource(Ref ref) => PlatformHealthSource();

/// Résultat de la dernière lecture du téléphone.
enum HealthSyncStatus { idle, disabled, denied, failed, synced }

/// Ce que montre l'écran Santé.
class HealthView {
  const HealthView({
    required this.today,
    required this.log,
    required this.status,
    required this.consent,
  });

  final HealthDay today;
  final HealthLog log;
  final HealthSyncStatus status;

  /// Faux tant que le joueur n'a pas autorisé la lecture de ses données.
  final bool consent;

  /// XP gagnée aujourd'hui grâce à la santé.
  Map<StatId, int> get todayXp => today.credited;
}

/// Santé du jour : lecture du téléphone (lecture seule), hydratation, XP
/// versée aux stats (une seule fois par journée et par source).
@Riverpod(keepAlive: true)
class HealthController extends _$HealthController {
  DateTime _now() => ref.read(clockProvider)();

  @override
  Future<HealthView> build() async {
    final profile = await ref.watch(playerProfileProvider.future);
    final log = await ref.read(healthRepositoryProvider).read();
    final today = CivilDate.ofLocal(_now());
    return HealthView(
      today: log.dayOf(today),
      log: log,
      status: HealthSyncStatus.idle,
      consent: profile?.healthConsent ?? false,
    );
  }

  /// Lit aujourd'hui et hier sur le téléphone, puis verse l'XP gagnée.
  Future<void> sync() async {
    final view = await future;
    if (!view.consent) {
      state = AsyncData(_view(view.log, HealthSyncStatus.disabled, view));
      return;
    }
    final source = ref.read(healthSourceProvider);
    if (!await source.authorize()) {
      state = AsyncData(_view(view.log, HealthSyncStatus.denied, view));
      return;
    }
    final sessions = await ref.read(completedSessionsProvider.future);
    final spans = [
      for (final s in sessions) (start: s.startedAt, end: s.endedAt),
    ];
    var log = view.log;
    for (final day in daysToRead(CivilDate.ofLocal(_now()))) {
      final start = DateTime(day.year, day.month, day.day);
      final end = DateTime(day.year, day.month, day.day + 1);
      final HealthReading reading;
      try {
        reading = await source.read(start, end);
      } on Exception {
        state = AsyncData(_view(log, HealthSyncStatus.failed, view));
        return;
      }
      final updated = withReading(
        log.dayOf(day),
        steps: reading.steps,
        activityMinutes: externalActivityMinutes(reading.activities, spans),
        sleepMinutes: reading.sleepMinutes,
      );
      log = upsertDay(log, await _credit(updated));
      await ref.read(healthRepositoryProvider).save(log);
    }
    state = AsyncData(_view(log, HealthSyncStatus.synced, view));
  }

  /// Ajoute ou retire un verre d'eau aujourd'hui.
  Future<void> addGlass(int delta) async {
    final view = await future;
    final day = await _credit(addGlasses(view.today, delta));
    final log = upsertDay(view.log, day);
    await ref.read(healthRepositoryProvider).save(log);
    state = AsyncData(_view(log, view.status, view));
  }

  /// Verse l'XP encore due pour la journée et la note comme versée.
  Future<HealthDay> _credit(HealthDay day) async {
    final pending = pendingHealthXp(day);
    if (pending.isEmpty) return day;
    await ref.read(progressionControllerProvider.notifier).addStatXp(pending);
    return markCredited(day, pending);
  }

  HealthView _view(HealthLog log, HealthSyncStatus status, HealthView before) =>
      HealthView(
        today: log.dayOf(CivilDate.ofLocal(_now())),
        log: log,
        status: status,
        consent: before.consent,
      );
}
