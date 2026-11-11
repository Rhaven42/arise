# ROADMAP.md — ARISE

> Une case par livrable. Avant chaque phase : plan court + validation. Après chaque phase : bilan (fait / comment tester / limites) puis cases cochées ici.
> Définition de « terminé » pour chaque phase : compile, se lance, `flutter analyze` et lint TS sans avertissement, tests verts, aucun TODO.

## Étape préalable
- [x] CLAUDE.md, docs/SPEC.md, docs/ANATOMY.md, docs/ROADMAP.md créés
- [x] Questions bloquantes répondues et documentation validée (décisions : SPEC.md §20)
- [x] Dépôt GitHub créé et relié à Claude

## Phase 0 — Fondations
- [x] Projet Flutter (Android + iOS) initialisé, identifiants d'application définis
- [x] Projet Firebase configuré + émulateurs — retiré en phase 1 (passage hors ligne)
- [x] Structure Clean Architecture (`core/`, `features/*/domain|data|presentation`, `functions/`, `assets/`, `test/` miroir)
- [x] Thème fantasy (couleurs, typographies médiévales sous licence libre, cadres pierre/bois)
- [x] Design system (boutons, cadres, fenêtre « Système », barres, badges) + page de démonstration
- [x] Navigation `go_router` + garde d'authentification
- [x] Riverpod + générateur configurés
- [x] Base locale Drift (schéma initial + migrations)
- [x] Configuration de jeu partagée (`game_config.dart` / `gameConfig.ts`) + **test de parité** — côté serveur retiré en phase 1
- [x] Localisation FR (ARB)
- [x] Lint strict Dart et TypeScript, zéro avertissement
- [x] Intégration continue (analyse, tests Flutter, tests Functions, parité, règles, lancement réel sur émulateur Android, APK de debug)

## Phase 1 — Accueil, questionnaire et sauvegarde (hors ligne)
- [x] Passage en 100 % hors ligne : retrait de Firebase et du serveur, doc mise à jour
- [x] Écran titre taverne
- [x] Questionnaire : objectif, niveau, équipement, 1 à 3 jours de repos, brouillon conservé
- [x] Consentement santé (révocable) et rappel de prudence
- [x] Profil enregistré dans la base locale (migration testée)
- [x] Navigation selon l'état du profil
- [x] Paramètres : export, import et effacement des données
- [x] Parcours complet testé sur émulateur Android

## Phase 2 — Exercices et planning
- [x] Catalogue des 27 exercices de référence conforme à ANATOMY.md, vérifié par un test
- [ ] Catalogue complété à 80 exercices (lots de 10 à valider — lot 1 validé et intégré : 37 exercices)
- [x] `ExerciseAnimationPlayer` + animations 2D de substitution (24 mouvements, muscles colorés)
- [x] Silhouettes SVG face et dos (33 zones), motifs + libellés pour les daltoniens
- [x] Fiche exercice (consignes, erreurs fréquentes, muscles, animation en boucle)
- [x] Exercices personnalisés avec sélection des muscles sur la silhouette
- [x] Éditeur de programmes (musculation, Tabata/HIIT/circuit, cardio, mobilité)
- [x] Planning hebdomadaire glisser-déposer, séances récurrentes, jours de repos
- [x] Rappels (notifications locales)
- [x] Base locale v3 (migration testée) et sauvegarde v2 (v1 toujours lisible)
- [x] Parcours sur émulateur : exercice, programme et planning

## Phase 3 — Lecteur de séance
- [x] Lecteur : minuteur visuel et sonore, voix optionnelle, animation synchronisée, compteur de séries
- [x] Saisie de l'intensité ressentie + avertissement douleur/fatigue
- [x] Enregistrement des séances dans la base locale (base v4, sauvegarde v3)
- [x] Récapitulatif (XP gagnée, muscles travaillés) — XP provisoire, plafond de 120 min appliqué
- [x] Parcours sur émulateur : lancement depuis le planning et arrêt de prudence

## Phase 4 — Moteur de progression
- [x] Calcul de l'XP par séance (bonus de série, malus de pénalité, plafond 120 min)
- [x] Niveaux, points de stat, cristaux par niveau
- [x] Rangs avec blocage au dernier niveau sans boss
- [x] Stats automatiques et répartition des points libres
- [x] Séries de jours, jours de repos, coffres 7/30/100/365
- [x] Boucliers, Zone de Pénalité, quête de pénalité (version simple : terminer une séance)
- [x] Mode maladie / blessure (≤ 14 jours)
- [x] Bascule quotidienne à l'ouverture, jours manqués inclus
- [x] Tests : changements d'heure, jours manqués multiples, boucliers, maladie, base v5 et sauvegarde v4
- [x] Fenêtre du Système (tableau de bord)

## Phase 5 — Analyse musculaire
- [x] Silhouettes SVG face et dos (33 zones identifiées)
- [x] Coloration post-exercice (principaux / secondaires)
- [x] Agrégats par période (jour, semaine, mois, année)
- [x] Seuils configurables + motifs + libellés (accessibilité daltonisme)
- [x] Indicateur de souplesse séparé
- [x] Suggestions basées sur le référentiel
- [x] Alertes poussée/tirage et avant/arrière

## Phase 6A — Créateur de personnage (livré)
- [x] Interface `CharacterRenderer` + rendu 3D hors ligne (three.js embarqué, modèles `.glb`)
- [x] Créateur à menus déroulants (race Humain/Elfe/Orque, sexe, coiffure, couleur de peau, couleur des cheveux) mettant à jour la fiche JSON avec rendu en direct
- [x] Six corps de substitution distincts (3 races × 2 sexes, homme et femme sur des maillages différents)
- [x] Curseurs corpulence et musculature (libellés bienveillants, différents par sexe) et taille
- [x] Tenue de départ et coiffures qui suivent la morphologie (mêmes formes que le corps)
- [x] Aléatoire, réinitialiser, annuler / rétablir (20 actions)
- [x] Nom : longueur + filtre anti-insultes ; brouillon local ; base v6, sauvegarde v5
- [x] Monnaie bronze / argent / or (gains selon la difficulté, niveaux, coffres) ; cristaux convertis
- [x] Parcours sur émulateur avec le vrai rendu 3D

## Phase 6B — Créateur avancé (livré)
- [x] Morphotype, posture, 12 préréglages par sexe
- [x] Écrans visage, yeux, sourcils, barbe, maquillage
- [x] Coiffures : catégories, favoris (verrouillage livré avec la boutique, phase 7)
- [x] Scène : 4 poses, 3 éclairages, capture, avant / après
- [x] `docs/ASSETS.md` complété (squelette, poses, équipements de la boutique)

## Phase 7 — Boutique et inventaire (livré)
- [x] Boutique (catégories, raretés, essayage)
- [x] Achat en pièces (bronze, argent, or)
- [x] Inventaire et équipement par emplacement
- [x] Teinture
- [x] Coupes de cheveux verrouillées

## Phase 8A — Quête quotidienne et épreuves de rang (livré)
- [x] Quête quotidienne générée par le moteur de jeu (catalogue validé, équipement, niveau), progression automatique, récompense et validation du jour
- [x] Quête de pénalité (moitié de la quête du jour)
- [x] Épreuves de rang (force, endurance, agilité), conditions d'accès, délai de 48 h
- [x] Récompenses de boss (rang, titre, objet exclusif teinté, fenêtre de victoire animée)
- [x] Base v8 et sauvegarde v7 (v6 toujours lisible), migration testée
- [x] Parcours sur émulateur : quête du jour et page d'épreuve

## Phase 8B — Quêtes hebdomadaires, donjons, classes (livré)
- [x] Quêtes hebdomadaires et d'événement
- [x] Donjons hebdomadaires (trois salles, une par jour, butin cosmétique)
- [x] Classes (choix au rang C, changement mensuel, bonus d'XP)
- [x] Sauvegarde v8 (v7 toujours lisible)

## Phase 9 — Hauts faits, titres, auras, Ombres
- [ ] 60 hauts faits (7 catégories, dont secrets)
- [ ] Titres équipables
- [ ] Auras cosmétiques
- [ ] Ombres (extraction rang B+, bonus passif, limites 5/7)

## Phase 10 — ~~Coach caméra~~ (retiré du MVP, SPEC §21)

## Phase 11 — Santé
- [ ] Health Connect / HealthKit en lecture seule
- [ ] Conversion plafonnée en Endurance / Vitalité
- [ ] Bonus sommeil ≥ 7 h
- [ ] Saisie manuelle de l'hydratation

## Phase 12 — Finitions et publication
- [x] Sons et ambiance (musiques et jingle fournis par la propriétaire du projet, 11/11/2026)
- [ ] Performances (profilage, temps de démarrage)
- [ ] Audit d'accessibilité
- [ ] Audit de confidentialité (aucune donnée ne quitte le téléphone sans action de l'utilisateur)
- [ ] Textes du store et politique de confidentialité
- [ ] Builds de publication Android et iOS
- [ ] Relecture du référentiel anatomique par un coach diplômé ou un kinésithérapeute
