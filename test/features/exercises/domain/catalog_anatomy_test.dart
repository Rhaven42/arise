import 'dart:convert';
import 'dart:io';

import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/exercises/data/asset_exercise_catalog_repository.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lit le tableau de correspondance de docs/ANATOMY.md (§2).
Map<String, ({List<String> primary, List<String> secondary})> _anatomyTable() {
  final doc = File('docs/ANATOMY.md').readAsStringSync();
  final section = doc
      .split('## 2. Mapping')[1]
      .split('## 2 bis')[0]
      .split('## 3.')[0];
  final row = RegExp(r'^\| .*\(`([a-z_]+)`\) \| (.*) \| (.*) \|$');
  List<String> split(String cell) => [
    for (final part in cell.split(','))
      if (part.trim().isNotEmpty && part.trim() != '—')
        part.replaceAll('(faiblement)', '').trim(),
  ];
  return {
    for (final line in section.split('\n'))
      if (row.firstMatch(line) case final m? when m.group(1) != 'id')
        m.group(1)!: (
          primary: split(m.group(2)!),
          secondary: split(m.group(3)!),
        ),
  };
}

void main() {
  final catalog = AssetExerciseCatalogRepository.decodeCatalog(
    File(AssetExerciseCatalogRepository.assetPath).readAsStringSync(),
  );
  final anatomy = _anatomyTable();

  test('chaque exercice validé reprend exactement le référentiel', () {
    final validated = [
      for (final e in catalog)
        if (e.reviewStatus == ReviewStatus.validated) e,
    ];
    expect(validated.map((e) => e.id).toSet(), anatomy.keys.toSet());
    for (final exercise in validated) {
      final row = anatomy[exercise.id]!;
      expect(
        exercise.primaryMuscles.map((m) => m.key).toList(),
        row.primary,
        reason: exercise.id,
      );
      expect(
        exercise.secondaryMuscles.map((m) => m.key).toList(),
        row.secondary,
        reason: exercise.id,
      );
    }
  });

  test('les identifiants sont uniques', () {
    final ids = [for (final e in catalog) e.id];
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('un muscle n’est jamais à la fois principal et secondaire', () {
    for (final e in catalog) {
      expect(
        e.primaryMuscles.toSet().intersection(e.secondaryMuscles.toSet()),
        isEmpty,
        reason: e.id,
      );
      expect(
        e.secondaryMuscles.toSet().containsAll(e.weakMuscles),
        isTrue,
        reason: e.id,
      );
    }
  });

  test('les stats totalisent 100 % et excluent la Volonté', () {
    for (final e in catalog) {
      final total = e.stats.values.fold<double>(0, (a, b) => a + b);
      expect(total, closeTo(1, 1e-9), reason: e.id);
      expect(e.stats.containsKey(StatId.willpower), isFalse, reason: e.id);
    }
  });

  test('les burpees répartissent 70 % Endurance et 30 % Force', () {
    final burpee = catalog.firstWhere((e) => e.id == 'burpee');
    expect(burpee.stats, {StatId.endurance: 0.7, StatId.strength: 0.3});
  });

  test('chaque exercice a une fiche complète et une animation existante', () {
    final motions = jsonDecode(
      File('assets/animations/motions.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final e in catalog) {
      expect(e.name, isNotEmpty, reason: e.id);
      expect(e.instructions, isNotEmpty, reason: e.id);
      expect(e.mistakes, isNotEmpty, reason: e.id);
      expect(e.difficulty, inInclusiveRange(1, 3), reason: e.id);
      expect(motions.containsKey(e.motion), isTrue, reason: e.id);
    }
  });

  test('les muscles du catalogue existent tous dans le référentiel', () {
    for (final e in catalog) {
      for (final m in [...e.primaryMuscles, ...e.secondaryMuscles]) {
        expect(MuscleId.tryParse(m.key), m);
      }
    }
  });
}
