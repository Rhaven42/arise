import 'package:flutter/material.dart';

/// Palette d'Arisia : pierre, bois, or et lueur de mana.
///
/// Contrastes vérifiés (WCAG AA) pour le texte : parchemin et or sur
/// abîme/pierre, texte sombre sur or.
abstract final class AriseColors {
  static const abyss = Color(0xFF14110F);
  static const stoneDark = Color(0xFF1F1B18);
  static const stone = Color(0xFF2B2622);
  static const stoneLight = Color(0xFF4A423B);
  static const wood = Color(0xFF5C3D24);
  static const woodLight = Color(0xFF8A5E3B);
  static const gold = Color(0xFFD4A84B);
  static const goldBright = Color(0xFFF0CC74);
  static const ember = Color(0xFFE07A2E);
  static const parchment = Color(0xFFEADBC0);
  static const parchmentMuted = Color(0xFFB9A98E);
  static const mana = Color(0xFF4FB3E8);
  static const danger = Color(0xFFE0735A);
  static const success = Color(0xFF7BC87A);
  static const onGold = Color(0xFF1B1408);

  // Silhouettes musculaires : la couleur est toujours doublée d'un motif
  // (hachures = principal, points = secondaire) pour les daltoniens.
  static const bodyFill = Color(0xFF4A423B);
  static const muscleIdle = Color(0xFF62574D);
  static const musclePrimary = Color(0xFF3DDC6A);
  static const musclePrimaryPattern = Color(0xFF0E4A20);
  static const muscleSecondary = Color(0xFFA8E6A3);
  static const muscleSecondaryPattern = Color(0xFF2F6A2B);
  static const muscleSelectedOutline = Color(0xFFF0CC74);

  // Heatmap musculaire (5 niveaux, chacun avec un motif distinct).
  static const heatLow = Color(0xFFE0735A);
  static const heatSome = Color(0xFFEBA543);
  static const heatPattern = Color(0xFF2A1A12);

  // Pièces de la bourse.
  static const coinGold = Color(0xFFE8BE4E);
  static const coinSilver = Color(0xFFC9CED6);
  static const coinBronze = Color(0xFFC07A45);

  // Raretés (toujours accompagnées d'un libellé et d'une icône).
  static const rarityCommon = Color(0xFFB9A98E);
  static const rarityRare = Color(0xFF5FA8E8);
  static const rarityEpic = Color(0xFFB98AF0);
  static const rarityLegendary = Color(0xFFF0A040);
  static const rarityMythic = Color(0xFFF07A8A);
}
