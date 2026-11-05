import 'package:freezed_annotation/freezed_annotation.dart';

/// Jour du calendrier (année, mois, jour), sans heure ni fuseau.
///
/// Les jours se comptent en dates civiles pour rester justes lors des
/// changements d'heure : un jour d'été ou d'hiver reste « un jour ».
@immutable
class CivilDate implements Comparable<CivilDate> {
  const CivilDate(this.year, this.month, this.day);

  /// Jour local du moment [moment] (converti dans le fuseau du téléphone).
  factory CivilDate.ofLocal(DateTime moment) {
    final local = moment.toLocal();
    return CivilDate(local.year, local.month, local.day);
  }

  /// Lit une date au format `AAAA-MM-JJ`.
  factory CivilDate.parse(String value) {
    final parts = value.split('-').map(int.parse).toList();
    return CivilDate(parts[0], parts[1], parts[2]);
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// Jour de la semaine, comme `DateTime.weekday` (1 = lundi).
  int get weekday => _utc.weekday;

  CivilDate addDays(int days) {
    final moved = _utc.add(Duration(days: days));
    return CivilDate(moved.year, moved.month, moved.day);
  }

  CivilDate get next => addDays(1);

  CivilDate get previous => addDays(-1);

  /// Nombre de jours de [other] à ce jour (positif si ce jour est après).
  int daysSince(CivilDate other) => _utc.difference(other._utc).inDays;

  bool isBefore(CivilDate other) => compareTo(other) < 0;

  bool isAfter(CivilDate other) => compareTo(other) > 0;

  @override
  int compareTo(CivilDate other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) =>
      other is CivilDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// Format `AAAA-MM-JJ`.
  @override
  String toString() {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${year.toString().padLeft(4, '0')}-${two(month)}-${two(day)}';
  }
}

/// Conversion JSON des dates civiles (`AAAA-MM-JJ`).
class CivilDateConverter implements JsonConverter<CivilDate, String> {
  const CivilDateConverter();

  @override
  CivilDate fromJson(String json) => CivilDate.parse(json);

  @override
  String toJson(CivilDate object) => object.toString();
}

/// Variante pour les dates facultatives.
class NullableCivilDateConverter implements JsonConverter<CivilDate?, String?> {
  const NullableCivilDateConverter();

  @override
  CivilDate? fromJson(String? json) =>
      json == null ? null : CivilDate.parse(json);

  @override
  String? toJson(CivilDate? object) => object?.toString();
}
