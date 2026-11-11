import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shadows_state.freezed.dart';
part 'shadows_state.g.dart';

/// Origine d'une Ombre : un boss de rang ou un donjon de la semaine.
enum ShadowSource { boss, dungeon }

/// Ombre à extraire (après une victoire) ou déjà extraite.
@freezed
abstract class ShadowOrigin with _$ShadowOrigin {
  const factory ShadowOrigin({
    required ShadowSource source,

    /// Identifiant stable de la victoire : `boss_<rang>` ou
    /// `dungeon_<lundi de la semaine>`.
    required String key,

    /// Boss (nom de `BossId`) ou thème du donjon (nom de `DungeonTheme`).
    required String name,

    /// Stat renforcée par l'Ombre.
    required StatId stat,
  }) = _ShadowOrigin;

  factory ShadowOrigin.fromJson(Map<String, dynamic> json) =>
      _$ShadowOriginFromJson(json);
}

/// Ombre extraite : compagnon cosmétique avec un bonus passif.
@freezed
abstract class Shadow with _$Shadow {
  const factory Shadow({
    required ShadowOrigin origin,
    required DateTime extractedAt,

    /// Numéro d'ordre (teinte de la silhouette).
    required int index,
  }) = _Shadow;

  const Shadow._();

  factory Shadow.fromJson(Map<String, dynamic> json) => _$ShadowFromJson(json);

  String get id => origin.key;
}

/// Armée d'Ombres du joueur.
@freezed
abstract class ShadowsState with _$ShadowsState {
  const factory ShadowsState({
    @Default([]) List<Shadow> shadows,

    /// Ombres actives, dans l'ordre d'activation.
    @Default([]) List<String> active,

    /// Victoires dont l'Ombre attend d'être extraite.
    @Default([]) List<ShadowOrigin> pending,
  }) = _ShadowsState;

  factory ShadowsState.fromJson(Map<String, dynamic> json) =>
      _$ShadowsStateFromJson(json);
}
