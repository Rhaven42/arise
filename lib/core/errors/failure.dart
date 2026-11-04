import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Erreur typée remontée par les repositories vers la présentation.
///
/// Les exceptions des SDK (Firebase, Drift…) sont converties en `Failure`
/// dans la couche `data` : l'interface ne manipule jamais d'exception brute.
@freezed
sealed class Failure with _$Failure {
  /// Réseau indisponible ou délai dépassé.
  const factory Failure.network({String? details}) = NetworkFailure;

  /// Utilisateur non connecté ou session expirée.
  const factory Failure.unauthenticated() = UnauthenticatedFailure;

  /// Action refusée par les règles de sécurité ou par le serveur.
  const factory Failure.permissionDenied({String? details}) =
      PermissionDeniedFailure;

  /// Ressource introuvable.
  const factory Failure.notFound({String? details}) = NotFoundFailure;

  /// Erreur de la base locale.
  const factory Failure.storage({String? details}) = StorageFailure;

  /// Erreur imprévue.
  const factory Failure.unexpected({String? details}) = UnexpectedFailure;
}
