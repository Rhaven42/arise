import 'dart:ui';

import 'package:arise/core/theme/arise_colors.dart' show AriseColors;

/// Couleurs et police des titres d'un univers. [AriseColors] lit la palette
/// active ; l'application se reconstruit quand elle change.
///
/// Contrastes (WCAG AA) gardés dans chaque palette : [parchment] et [gold]
/// sur [abyss] / [stone], [onGold] sur [gold].
class WorldPalette {
  const WorldPalette({
    required this.id,
    required this.abyss,
    required this.stoneDark,
    required this.stone,
    required this.stoneLight,
    required this.wood,
    required this.woodLight,
    required this.gold,
    required this.goldBright,
    required this.goldPale,
    required this.goldDeep,
    required this.goldShadow,
    required this.bronzeEdge,
    required this.panelTop,
    required this.panelBottom,
    required this.backdropTop,
    required this.backdropBottom,
    required this.onGold,
    required this.parchment,
    required this.parchmentMuted,
    required this.ember,
    required this.displayFont,
  });

  /// Identifiant de l'univers (`medieval`, `arcane`, `north`, `sea`), pour
  /// les textes propres à chaque univers.
  final String id;

  final Color abyss;
  final Color stoneDark;
  final Color stone;
  final Color stoneLight;
  final Color wood;
  final Color woodLight;
  final Color gold;
  final Color goldBright;
  final Color goldPale;
  final Color goldDeep;
  final Color goldShadow;
  final Color bronzeEdge;
  final Color panelTop;
  final Color panelBottom;
  final Color backdropTop;
  final Color backdropBottom;
  final Color onGold;
  final Color parchment;
  final Color parchmentMuted;
  final Color ember;

  /// Police des titres et des boutons.
  final String displayFont;

  /// Palette en cours (Médiéval au démarrage).
  static WorldPalette active = medieval;

  /// Médiéval : pierre, bois et or.
  static const medieval = WorldPalette(
    id: 'medieval',
    abyss: Color(0xFF14110F),
    stoneDark: Color(0xFF1F1B18),
    stone: Color(0xFF2B2622),
    stoneLight: Color(0xFF4A423B),
    wood: Color(0xFF5C3D24),
    woodLight: Color(0xFF8A5E3B),
    gold: Color(0xFFD4A84B),
    goldBright: Color(0xFFF0CC74),
    goldPale: Color(0xFFFFE8A8),
    goldDeep: Color(0xFFB9852E),
    goldShadow: Color(0xFF5A3D12),
    bronzeEdge: Color(0xFF6B5326),
    panelTop: Color(0xFF2B2622),
    panelBottom: Color(0xFF1C1815),
    backdropTop: Color(0xFF221C18),
    backdropBottom: Color(0xFF120F0D),
    onGold: Color(0xFF1B1408),
    parchment: Color(0xFFEADBC0),
    parchmentMuted: Color(0xFFB9A98E),
    ember: Color(0xFFE07A2E),
    displayFont: 'Cinzel',
  );

  /// Magie : bleu nuit, bordeaux et or ancien.
  static const arcane = WorldPalette(
    id: 'arcane',
    abyss: Color(0xFF0A0F1F),
    stoneDark: Color(0xFF111A33),
    stone: Color(0xFF1A2444),
    stoneLight: Color(0xFF3A4672),
    wood: Color(0xFF6B0F1A),
    woodLight: Color(0xFF9A2A36),
    gold: Color(0xFFC9A227),
    goldBright: Color(0xFFE8C65A),
    goldPale: Color(0xFFF6E4A6),
    goldDeep: Color(0xFFA27F16),
    goldShadow: Color(0xFF4A3A08),
    bronzeEdge: Color(0xFF5E4A1A),
    panelTop: Color(0xFF1A2444),
    panelBottom: Color(0xFF0F1630),
    backdropTop: Color(0xFF1B1430),
    backdropBottom: Color(0xFF070B18),
    onGold: Color(0xFF14100A),
    parchment: Color(0xFFE8E2F2),
    parchmentMuted: Color(0xFFB2ABCB),
    ember: Color(0xFFC0569A),
    displayFont: 'Metamorphous',
  );

  /// Viking : bleu glacier, bois brun et blanc neige.
  static const north = WorldPalette(
    id: 'north',
    abyss: Color(0xFF0E1318),
    stoneDark: Color(0xFF161D25),
    stone: Color(0xFF1F2933),
    stoneLight: Color(0xFF3E4C5A),
    wood: Color(0xFF5C3A21),
    woodLight: Color(0xFF8A5E3B),
    gold: Color(0xFF8FB9E2),
    goldBright: Color(0xFFCFE4F7),
    goldPale: Color(0xFFEDEFF2),
    goldDeep: Color(0xFF3A6EA5),
    goldShadow: Color(0xFF1B3550),
    bronzeEdge: Color(0xFF4E6378),
    panelTop: Color(0xFF1F2933),
    panelBottom: Color(0xFF151C24),
    backdropTop: Color(0xFF1A2430),
    backdropBottom: Color(0xFF0A0E12),
    onGold: Color(0xFF0B1620),
    parchment: Color(0xFFEDEFF2),
    parchmentMuted: Color(0xFFAEB8C2),
    ember: Color(0xFFE07A2E),
    displayFont: 'UncialAntiqua',
  );

  /// Pirate : bleu océan, sable et rouge corsaire.
  static const sea = WorldPalette(
    id: 'sea',
    abyss: Color(0xFF061820),
    stoneDark: Color(0xFF0A222D),
    stone: Color(0xFF0E3140),
    stoneLight: Color(0xFF2B5566),
    wood: Color(0xFF8B1E1E),
    woodLight: Color(0xFFB03A3A),
    gold: Color(0xFFE8C872),
    goldBright: Color(0xFFF5DE9C),
    goldPale: Color(0xFFFFF0C8),
    goldDeep: Color(0xFFC09A3C),
    goldShadow: Color(0xFF5A4512),
    bronzeEdge: Color(0xFF6E5A2A),
    panelTop: Color(0xFF0E3140),
    panelBottom: Color(0xFF09222D),
    backdropTop: Color(0xFF0E4D64),
    backdropBottom: Color(0xFF051218),
    onGold: Color(0xFF1B1408),
    parchment: Color(0xFFF2E6C8),
    parchmentMuted: Color(0xFFC2B48E),
    ember: Color(0xFFE0653A),
    displayFont: 'PirataOne',
  );
}
