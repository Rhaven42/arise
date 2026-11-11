import 'package:arise/features/shadows/domain/shadows_state.dart';

/// Stockage local de l'état « shadows ».
abstract interface class ShadowsRepository {
  Future<ShadowsState> read();

  Stream<ShadowsState> watch();

  Future<void> save(ShadowsState state);
}
