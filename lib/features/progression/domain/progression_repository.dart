import 'package:arise/features/progression/domain/progression_state.dart';

/// Stockage de la progression du joueur.
abstract interface class ProgressionRepository {
  /// Progression enregistrée, ou `null` si elle n'a jamais été calculée.
  Future<ProgressionState?> read();

  Stream<ProgressionState?> watch();

  Future<void> save(ProgressionState state);
}
