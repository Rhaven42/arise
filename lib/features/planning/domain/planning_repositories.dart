import 'package:arise/features/planning/domain/planned_session.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/planning/domain/schedule.dart';

/// Programmes du joueur.
abstract interface class ProgramRepository {
  Stream<List<Program>> watchAll();

  Future<void> save(Program program);

  /// Supprime le programme et les séances planifiées qui l'utilisent.
  Future<void> delete(String id);
}

/// Séances planifiées.
abstract interface class PlanningRepository {
  Stream<List<PlannedSession>> watchAll();

  Future<void> save(PlannedSession session);

  Future<void> delete(String id);
}

/// Programmation des rappels sur le téléphone.
abstract interface class ReminderScheduler {
  /// Demande l'autorisation d'afficher des notifications.
  Future<bool> requestPermission();

  /// Remplace tous les rappels programmés par [reminders].
  Future<void> replaceAll(List<ReminderRequest> reminders);
}
