import 'package:arise/features/titles/domain/titles_state.dart';

/// Stockage local de l'état « titles ».
abstract interface class TitlesRepository {
  Future<TitlesState> read();

  Stream<TitlesState> watch();

  Future<void> save(TitlesState state);
}
