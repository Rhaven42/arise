import 'package:arise/core/config/game_config.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'trials_state.freezed.dart';
part 'trials_state.g.dart';

/// Historique des épreuves de rang.
///
/// Les boss vaincus sont dans la progression (`defeatedBosses`) : c'est elle
/// qui débloque le passage de rang. Ici sont gardés les essais, le délai
/// après une défaite et les titres gagnés.
@freezed
abstract class TrialsState with _$TrialsState {
  const factory TrialsState({
    /// Dernière défaite par rang (UTC) : nouvel essai 48 h plus tard.
    @Default({}) Map<RankId, DateTime> lastDefeatAt,

    /// Nombre d'essais par rang.
    @Default({}) Map<RankId, int> attempts,

    /// Titres gagnés (identifiants stables), dans l'ordre d'obtention.
    @Default([]) List<String> titles,
  }) = _TrialsState;

  factory TrialsState.fromJson(Map<String, dynamic> json) =>
      _$TrialsStateFromJson(json);
}
