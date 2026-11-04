import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

/// Utilisateur authentifié, indépendant du fournisseur d'identité.
@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({required String uid, String? displayName}) =
      _AuthUser;
}
