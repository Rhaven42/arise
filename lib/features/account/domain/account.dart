import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';

/// Compte local : un joueur du téléphone, avec sa propre base de données.
@freezed
abstract class Account with _$Account {
  const factory Account({
    required String id,

    /// Pseudo choisi par le joueur (vide pour le compte repris d'une
    /// installation antérieure aux comptes, tant qu'il n'est pas renommé).
    required String name,

    /// Nom de la base Drift du compte (fichier `<nom>.sqlite`).
    required String databaseName,

    required DateTime createdAt,
    required DateTime lastUsedAt,

    /// Empreinte du code PIN facultatif, et son sel.
    String? pinHash,
    String? pinSalt,
  }) = _Account;

  const Account._();

  bool get hasPin => pinHash != null;

  /// Pseudo, ou [fallback] pour le compte repris sans pseudo.
  String displayName(String fallback) => name.isEmpty ? fallback : name;
}
