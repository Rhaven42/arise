import 'package:arise/features/workout_player/domain/completed_session.dart';

/// Historique des séances réalisées.
abstract interface class CompletedSessionRepository {
  Stream<List<CompletedSession>> watchAll();

  Future<List<CompletedSession>> readAll();

  Future<void> save(CompletedSession session);
}
