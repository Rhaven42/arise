import 'package:arise/core/audio/music.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chaque écran a sa musique, la séance reste silencieuse', () {
    expect(musicForLocation(AppRoutes.title), MusicTrack.title);
    expect(musicForLocation(AppRoutes.onboarding), MusicTrack.title);
    expect(musicForLocation(AppRoutes.systemHome), MusicTrack.system);
    expect(musicForLocation(AppRoutes.planning), MusicTrack.system);
    expect(musicForLocation(AppRoutes.shop), MusicTrack.shop);
    expect(musicForLocation(AppRoutes.inventory), MusicTrack.shop);
    expect(musicForLocation(AppRoutes.workout('p1')), isNull);
  });
}
