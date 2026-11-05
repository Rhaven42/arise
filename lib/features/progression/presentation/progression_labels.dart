import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:intl/intl.dart';

/// Date civile au format français, par exemple « 12 novembre 2026 ».
String formatCivilDate(CivilDate date) => DateFormat.yMMMMd(
  'fr',
).format(DateTime(date.year, date.month, date.day));
