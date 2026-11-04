/// Clés des jours de la semaine, indexées comme `DateTime.weekday` - 1.
///
/// Utilisées pour les messages traduits (`weekdayShort`, `weekdayLong`).
const weekdayKeys = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

/// Clé de traduction d'un jour (1 = lundi … 7 = dimanche).
String weekdayKey(int weekday) => weekdayKeys[weekday - DateTime.monday];
