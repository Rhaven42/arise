import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'avance d’un jour à travers les mois, les années et les bissextiles',
    () {
      expect(const CivilDate(2026, 1, 31).next, const CivilDate(2026, 2, 1));
      expect(const CivilDate(2026, 12, 31).next, const CivilDate(2027, 1, 1));
      expect(const CivilDate(2028, 2, 28).next, const CivilDate(2028, 2, 29));
      expect(
        const CivilDate(2026, 3, 1).previous,
        const CivilDate(2026, 2, 28),
      );
    },
  );

  test('les changements d’heure ne faussent pas le compte des jours', () {
    // Passage à l'heure d'été (29 mars 2026) et d'hiver (25 octobre 2026)
    // en France : chaque jour reste un jour.
    const spring = CivilDate(2026, 3, 28);
    expect(spring.addDays(2), const CivilDate(2026, 3, 30));
    expect(const CivilDate(2026, 3, 30).daysSince(spring), 2);
    const autumn = CivilDate(2026, 10, 24);
    expect(autumn.addDays(2), const CivilDate(2026, 10, 26));
    expect(const CivilDate(2026, 10, 26).daysSince(autumn), 2);
  });

  test('donne le jour de la semaine comme DateTime.weekday', () {
    expect(const CivilDate(2026, 11, 2).weekday, DateTime.monday);
    expect(const CivilDate(2026, 11, 8).weekday, DateTime.sunday);
  });

  test('se compare, s’égale et se convertit en texte', () {
    const a = CivilDate(2026, 11, 5);
    expect(a, const CivilDate(2026, 11, 5));
    expect(a.isBefore(a.next), isTrue);
    expect(a.next.isAfter(a), isTrue);
    expect(a.toString(), '2026-11-05');
    expect(CivilDate.parse('2026-11-05'), a);
    expect(
      const CivilDateConverter().fromJson('2026-01-09'),
      const CivilDate(2026, 1, 9),
    );
  });

  test('prend le jour local d’un instant', () {
    final local = DateTime(2026, 11, 5, 23, 59);
    expect(CivilDate.ofLocal(local), const CivilDate(2026, 11, 5));
  });
}
