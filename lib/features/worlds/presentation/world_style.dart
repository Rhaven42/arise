import 'package:arise/core/audio/music.dart';
import 'package:arise/core/theme/world_palette.dart';
import 'package:arise/features/worlds/domain/world.dart';

/// Palette (couleurs et police des titres) de chaque univers.
WorldPalette paletteOf(World world) => switch (world) {
  World.medieval => WorldPalette.medieval,
  World.arcane => WorldPalette.arcane,
  World.north => WorldPalette.north,
  World.sea => WorldPalette.sea,
};

/// Musiques propres à chaque univers (`assets/music/<univers>/`) ; un écran
/// sans piste dédiée garde la musique Médiéval.
MusicVariant? musicVariantOf(World world) => switch (world) {
  World.medieval => null,
  World.arcane => const MusicVariant(
    'arcane',
    tracks: {MusicTrack.title, MusicTrack.system, MusicTrack.shop},
    jingles: {Jingle.levelUp},
  ),
  World.north => const MusicVariant('north', tracks: {MusicTrack.system}),
  World.sea => null,
};
