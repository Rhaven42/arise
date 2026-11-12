import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/features/exercises/presentation/animation/figure_animation.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'coach_video_demo.g.dart';

/// Dossier des vidéos du prof d'un monde (voir `tool/coach`).
String coachVideoFolder(String world) => 'assets/coach_videos/$world';

/// Vidéo en boucle du prof pour un mouvement.
String coachVideoAsset(String world, String motionId) =>
    '${coachVideoFolder(world)}/$motionId.webp';

/// Image fixe (milieu du mouvement) : pause et animations réduites.
String coachVideoStill(String world, String motionId) =>
    '${coachVideoFolder(world)}/${motionId}_still.webp';

/// Monde dont le prof montre les exercices (le Médiéval, en attendant les
/// autres mondes).
@Riverpod(keepAlive: true)
String coachWorld(Ref ref) => 'medieval';

/// Mouvements filmés par le prof du monde, avec leur image fixe.
@Riverpod(keepAlive: true)
Future<Set<String>> coachVideoIds(Ref ref, String world) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final assets = manifest.listAssets().toSet();
  final prefix = '${coachVideoFolder(world)}/';
  return {
    for (final asset in assets)
      if (asset.startsWith(prefix) &&
          asset.endsWith('.webp') &&
          !asset.endsWith('_still.webp'))
        if (asset.substring(prefix.length, asset.length - 5) case final id
            when assets.contains(coachVideoStill(world, id)))
          id,
  };
}

/// Le prof du monde montre l'exercice en vidéo ; sans vidéo pour ce
/// mouvement, le mannequin 2D prend le relais.
class CoachVideoDemo extends ConsumerStatefulWidget {
  const CoachVideoDemo({
    required this.motionId,
    required this.highlights,
    required this.semanticLabel,
    super.key,
  });

  static const pauseKey = Key('coach-video-pause');

  final String? motionId;
  final Map<MuscleId, MuscleRole> highlights;
  final String semanticLabel;

  @override
  ConsumerState<CoachVideoDemo> createState() => _CoachVideoDemoState();
}

class _CoachVideoDemoState extends ConsumerState<CoachVideoDemo> {
  bool _paused = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final world = ref.watch(coachWorldProvider);
    final videos = ref.watch(coachVideoIdsProvider(world));
    final motionId = widget.motionId;
    if (!videos.hasValue && !videos.hasError) {
      return Semantics(label: widget.semanticLabel, child: const SizedBox());
    }
    if (motionId == null || !(videos.value?.contains(motionId) ?? false)) {
      return FigureAnimation(
        motionId: motionId,
        highlights: widget.highlights,
        semanticLabel: widget.semanticLabel,
      );
    }
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final still = _paused || reduceMotion;
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              still
                  ? coachVideoStill(world, motionId)
                  : coachVideoAsset(world, motionId),
              key: ValueKey('$motionId-$still'),
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
          if (!reduceMotion)
            Positioned(
              right: 4,
              bottom: 4,
              child: Material(
                color: AriseColors.abyss.withValues(alpha: 0.6),
                shape: const CircleBorder(),
                child: IconButton(
                  key: CoachVideoDemo.pauseKey,
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
      ),
    );
  }
}
