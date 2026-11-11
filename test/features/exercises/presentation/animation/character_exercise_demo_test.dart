import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:arise/features/avatar/domain/character_scene.dart';
import 'package:arise/features/exercises/presentation/animation/character_exercise_demo.dart';
import 'package:arise/features/exercises/presentation/animation/figure_motion.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  test('le cadrage suit la vue du mouvement', () {
    expect(
      CharacterExerciseDemo.focusFor(MotionView.side),
      SceneFocus.exerciseSide,
    );
    expect(
      CharacterExerciseDemo.focusFor(testMotions['jumping_jack']!.view),
      SceneFocus.exerciseFront,
    );
  });

  test('chaque modèle 3D contient un clip par mouvement', () {
    for (final file in Directory('assets/models').listSync()) {
      if (!file.path.endsWith('.glb')) continue;
      final clips = _animationNames(File(file.path).readAsBytesSync());
      for (final id in testMotions.keys) {
        expect(clips, contains('ex_$id'), reason: file.path);
      }
    }
  });
}

/// Noms des animations d'un fichier glb (premier bloc : JSON).
Set<String> _animationNames(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final length = data.getUint32(12, Endian.little);
  final json = jsonDecode(
    utf8.decode(bytes.sublist(20, 20 + length)),
  ) as Map<String, dynamic>;
  return {
    for (final animation in json['animations'] as List<dynamic>)
      (animation as Map<String, dynamic>)['name'] as String,
  };
}
