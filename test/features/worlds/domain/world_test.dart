import 'package:arise/core/audio/music.dart';
import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/worlds/domain/world.dart';
import 'package:arise/features/worlds/presentation/world_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chaque univers hors Médiéval a son haut fait d’appel', () {
    expect(unlockDefinitionOf(World.medieval), isNull);
    expect(unlockDefinitionOf(World.north)?.threshold, 25);
    expect(unlockDefinitionOf(World.sea)?.threshold, 30);
    expect(
      unlockDefinitionOf(World.arcane)?.metric,
      AchievementMetric.arcaneCallSessions,
    );
    expect(worldFromName('sea'), World.sea);
    expect(worldFromName('inconnu'), World.medieval);
  });

  test('musiques : celles de l’univers, sinon celles du Médiéval', () {
    final arcane = musicVariantOf(World.arcane);
    final north = musicVariantOf(World.north);
    expect(
      MusicVariant.trackPath(arcane, MusicTrack.shop),
      'music/arcane/shop.mp3',
    );
    expect(
      MusicVariant.jinglePath(arcane, Jingle.levelUp),
      'music/arcane/level_up.mp3',
    );
    expect(
      MusicVariant.trackPath(north, MusicTrack.system),
      'music/north/system.mp3',
    );
    expect(MusicVariant.trackPath(north, MusicTrack.shop), 'music/shop.mp3');
    expect(
      MusicVariant.trackPath(musicVariantOf(World.sea), MusicTrack.title),
      'music/title.mp3',
    );
    expect(
      MusicVariant.jinglePath(null, Jingle.levelUp),
      'sounds/level_up.mp3',
    );
  });
}
