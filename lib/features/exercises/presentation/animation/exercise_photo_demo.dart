import 'dart:async';

import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/exercises/presentation/animation/figure_animation.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exercise_photo_demo.g.dart';

/// Dossier des photos de démonstration (free-exercise-db, domaine public).
const String exercisePhotoFolder = 'assets/exercise_photos';

/// Photo [frame] (0 = départ, 1 = arrivée) d'un exercice.
String exercisePhotoAsset(String exerciseId, int frame) =>
    '$exercisePhotoFolder/${exerciseId}_$frame.webp';

/// Exercices qui ont leurs deux photos dans l'application.
@Riverpod(keepAlive: true)
Future<Set<String>> exercisePhotoIds(Ref ref) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  const prefix = '$exercisePhotoFolder/';
  final assets = manifest.listAssets().toSet();
  return {
    for (final asset in assets)
      if (asset.startsWith(prefix) && asset.endsWith('_0.webp'))
        if (asset.substring(prefix.length, asset.length - 7) case final id
            when assets.contains(exercisePhotoAsset(id, 1)))
          id,
  };
}

/// Démonstration d'un exercice par un athlète : la photo de départ et celle
/// d'arrivée alternent en fondu, comme une courte vidéo.
///
/// Le mannequin 2D prend le relais pour un exercice sans photo (exercices
/// personnalisés, mouvements absents de la base).
class ExercisePhotoDemo extends ConsumerStatefulWidget {
  const ExercisePhotoDemo({
    required this.exerciseId,
    required this.motionId,
    required this.highlights,
    required this.semanticLabel,
    super.key,
  });

  /// Durée d'affichage de chaque pose.
  static const holdDuration = Duration(milliseconds: 1300);
  static const fadeDuration = Duration(milliseconds: 450);

  static const pauseKey = Key('exercise-photo-pause');

  final String exerciseId;
  final String? motionId;
  final Map<MuscleId, MuscleRole> highlights;
  final String semanticLabel;

  @override
  ConsumerState<ExercisePhotoDemo> createState() => _ExercisePhotoDemoState();
}

class _ExercisePhotoDemoState extends ConsumerState<ExercisePhotoDemo> {
  Timer? _timer;
  int _frame = 0;
  bool _paused = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Lance ou arrête l'alternance selon la pause et les réglages système.
  void _sync({required bool run}) {
    if (run && _timer == null) {
      _timer = Timer.periodic(ExercisePhotoDemo.holdDuration, (_) {
        if (mounted) setState(() => _frame = 1 - _frame);
      });
    } else if (!run && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void didUpdateWidget(covariant ExercisePhotoDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nouvel exercice (séance) : on repart de la pose de départ.
    if (oldWidget.exerciseId != widget.exerciseId) _frame = 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ids = ref.watch(exercisePhotoIdsProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!ids.hasValue && !ids.hasError) {
      return Semantics(label: widget.semanticLabel, child: const SizedBox());
    }
    if (!(ids.value?.contains(widget.exerciseId) ?? false)) {
      _sync(run: false);
      return FigureAnimation(
        motionId: widget.motionId,
        highlights: widget.highlights,
        semanticLabel: widget.semanticLabel,
      );
    }
    _sync(run: !_paused && !reduceMotion);
    Widget photo(int frame) => ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        exercisePhotoAsset(widget.exerciseId, frame),
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
    final Widget content;
    if (reduceMotion) {
      // Animations réduites : les deux poses côte à côte, sans mouvement.
      content = Row(
        children: [
          for (final (frame, label) in [
            (0, l10n.exercisePhotoStart),
            (1, l10n.exercisePhotoEnd),
          ]) ...[
            if (frame == 1) const SizedBox(width: AriseSpacing.xs),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: photo(frame)),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ],
      );
    } else {
      content = Stack(
        fit: StackFit.expand,
        children: [
          // Les deux photos restent chargées : le fondu ne clignote pas.
          photo(0),
          AnimatedOpacity(
            opacity: _frame == 1 ? 1 : 0,
            duration: ExercisePhotoDemo.fadeDuration,
            curve: Curves.easeInOut,
            child: photo(1),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Material(
              color: AriseColors.abyss.withValues(alpha: 0.6),
              shape: const CircleBorder(),
              child: IconButton(
                key: ExercisePhotoDemo.pauseKey,
                tooltip: _paused ? l10n.animationPlay : l10n.animationPause,
                icon: Icon(
                  _paused ? Icons.play_arrow : Icons.pause,
                  color: AriseColors.goldBright,
                ),
                onPressed: () => setState(() => _paused = !_paused),
              ),
            ),
          ),
        ],
      );
    }
    return Semantics(label: widget.semanticLabel, image: true, child: content);
  }
}
