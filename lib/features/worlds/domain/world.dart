/// Univers de l'application : chacun change l'ambiance (couleurs, polices,
/// musiques, noms), jamais la progression, qui reste commune.
enum World {
  medieval,
  arcane,
  north,
  sea;

  /// Haut fait qui ouvre l'univers ; aucun pour le Médiéval, ouvert
  /// d'office.
  String? get unlockAchievement => switch (this) {
    World.medieval => null,
    World.arcane => 'realm_arcane',
    World.north => 'realm_north',
    World.sea => 'realm_sea',
  };
}

/// Matière d'une tenue ou d'une pièce, pour les filtres de la boutique et du
/// sac.
enum EquipmentMaterial { plate, mail, leather, cloth }

/// L'univers [world] est ouvert quand son haut fait est obtenu.
bool isWorldUnlocked(World world, Set<String> unlockedAchievements) {
  final id = world.unlockAchievement;
  return id == null || unlockedAchievements.contains(id);
}

/// Univers d'après son nom stocké ; le Médiéval par défaut.
World worldFromName(String? name) => World.values.firstWhere(
  (w) => w.name == name,
  orElse: () => World.medieval,
);
