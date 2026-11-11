import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_profile.freezed.dart';
part 'player_profile.g.dart';

/// Objectif principal choisi pendant le questionnaire.
enum FitnessGoal {
  strength,
  weightLoss,
  endurance,
  flexibility,
  generalFitness,
}

/// Niveau sportif déclaré.
enum FitnessLevel { beginner, intermediate, advanced }

/// Équipement disponible. Aucun équipement = poids du corps uniquement.
enum Equipment {
  dumbbells,
  barbell,
  kettlebell,
  pullUpBar,
  dipBars,
  bench,
  resistanceBands,
  jumpRope,
  yogaMat,
  stationaryBike,
  rowingMachine,
}

/// Profil du joueur, issu du questionnaire d'arrivée.
@freezed
abstract class PlayerProfile with _$PlayerProfile {
  const factory PlayerProfile({
    required FitnessGoal goal,
    required FitnessLevel level,
    required Set<Equipment> equipment,

    /// Jours de repos, numérotés comme `DateTime.weekday` (1 = lundi).
    required Set<int> restDays,

    /// Consentement à la lecture des données de santé (révocable).
    required bool healthConsent,
    required DateTime createdAt,

    /// Lecteur de séance : bips et vibrations (activés par défaut).
    @Default(true) bool workoutSounds,

    /// Lecteur de séance : annonces vocales (désactivées par défaut).
    @Default(false) bool workoutVoice,

    /// Musique d'ambiance et jingles (activés par défaut).
    @Default(true) bool music,
  }) = _PlayerProfile;

  factory PlayerProfile.fromJson(Map<String, dynamic> json) =>
      _$PlayerProfileFromJson(json);
}
