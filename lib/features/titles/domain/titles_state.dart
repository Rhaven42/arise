import 'package:freezed_annotation/freezed_annotation.dart';

part 'titles_state.freezed.dart';
part 'titles_state.g.dart';

/// Titre affiché sous le nom et aura choisie.
@freezed
abstract class TitlesState with _$TitlesState {
  const factory TitlesState({String? equippedTitle, String? equippedAura}) =
      _TitlesState;

  factory TitlesState.fromJson(Map<String, dynamic> json) =>
      _$TitlesStateFromJson(json);
}
