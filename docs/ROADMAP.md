# ROADMAP.md — ARISE

> Une case par livrable. Avant chaque phase : plan court + validation. Après chaque phase : bilan (fait / comment tester / limites) puis cases cochées ici.
> Définition de « terminé » pour chaque phase : compile, se lance, `flutter analyze` et lint TS sans avertissement, tests verts, aucun TODO.

## Étape préalable
- [x] CLAUDE.md, docs/SPEC.md, docs/ANATOMY.md, docs/ROADMAP.md créés
- [x] Questions bloquantes répondues et documentation validée (décisions : SPEC.md §20)
- [ ] Dépôt GitHub créé et relié à Claude

## Phase 0 — Fondations
- [ ] Projet Flutter (Android + iOS) initialisé, identifiants d'application définis
- [ ] Projet Firebase configuré + émulateurs (Auth, Firestore, Functions, Storage)
- [ ] Structure Clean Architecture (`core/`, `features/*/domain|data|presentation`, `functions/`, `assets/`, `test/` miroir)
- [ ] Thème fantasy (couleurs, typographies médiévales sous licence libre, cadres pierre/bois)
- [ ] Design system (boutons, cadres, fenêtre « Système », barres, badges) + page de démonstration
- [ ] Navigation `go_router` + garde d'authentification
- [ ] Riverpod + générateur configurés
- [ ] Base locale Drift (schéma initial + migrations)
- [ ] Configuration de jeu partagée (`game_config.dart` / `gameConfig.ts`) + **test de parité**
- [ ] Localisation FR (ARB)
- [ ] Lint strict Dart et TypeScript, zéro avertissement
- [ ] Intégration continue (analyse, tests Flutter, tests Functions, parité, règles)

## Phase 1 — Authentification et onboarding
- [ ] Écran titre taverne
- [ ] Connexion Google
- [ ] Création de l'utilisateur côté serveur (`onUserCreated`)
- [ ] Questionnaire : objectif, niveau, équipement, 1 à 3 jours de repos
- [ ] Consentements santé et caméra (révocables)
- [ ] Règles de sécurité Firestore + tests sur émulateur

## Phase 2 — Exercices et planning
- [ ] Catalogue de 80 exercices conforme à ANATOMY.md (statut de relecture renseigné)
- [ ] `ExerciseAnimationPlayer` + animations de substitution
- [ ] Fiche exercice (consignes, erreurs fréquentes, muscles, animation en boucle)
- [ ] Exercices personnalisés avec sélection des muscles sur la silhouette
- [ ] Éditeur de programmes (musculation, Tabata/HIIT/circuit, cardio, mobilité)
- [ ] Planning hebdomadaire glisser-déposer, séances récurrentes, jours de repos
- [ ] Rappels (notifications)

## Phase 3 — Lecteur de séance
- [ ] Lecteur : minuteur visuel et sonore, voix optionnelle, animation synchronisée, compteur de séries
- [ ] Saisie de l'intensité ressentie + avertissement douleur/fatigue
- [ ] Mode hors ligne (Drift) et synchronisation
- [ ] Récapitulatif (XP confirmée serveur, muscles travaillés)

## Phase 4 — Moteur de progression (serveur)
- [ ] Calcul de l'XP par série (formule complète, plafond 120 min)
- [ ] Niveaux, points de stat, cristaux par niveau
- [ ] Rangs avec blocage au dernier niveau sans boss
- [ ] Stats automatiques et répartition des points libres
- [ ] Séries de jours, jours de repos, coffres 7/30/100/365
- [ ] Boucliers, Zone de Pénalité, quête de pénalité
- [ ] Mode maladie / blessure (≤ 14 jours)
- [ ] `dailyTick` par fuseau horaire
- [ ] Tests exhaustifs : fuseaux horaires, changement d'heure, cas limites
- [ ] Fenêtre du Système (tableau de bord)

## Phase 5 — Analyse musculaire
- [ ] Silhouettes SVG face et dos (33 zones identifiées)
- [ ] Coloration post-exercice (principaux / secondaires)
- [ ] Agrégats serveur par période (jour, semaine, mois, année)
- [ ] Seuils configurables + motifs + libellés (accessibilité daltonisme)
- [ ] Indicateur de souplesse séparé
- [ ] Suggestions basées sur le référentiel
- [ ] Alertes poussée/tirage et avant/arrière

## Phase 6 — Création du personnage
- [ ] Interface `CharacterRenderer` + implémentation glb
- [ ] Deux mannequins de substitution distincts (homme / femme)
- [ ] Écrans morphologie (curseurs, morphotype, posture, 12 préréglages par sexe)
- [ ] Écrans visage, yeux, sourcils, barbe, maquillage
- [ ] Écrans coiffures (catégories, couleurs, favoris, verrouillage)
- [ ] Scène de l'éditeur (360°, zoom, 4 poses, 3 éclairages, capture, aléatoire, reset, undo/redo ×20, avant/après)
- [ ] Nom : filtre + réservation serveur ; brouillon local
- [ ] `docs/ASSETS.md` : cahier des charges complet de l'artiste 3D

## Phase 7 — Boutique et inventaire
- [ ] Boutique (catégories, raretés, essayage)
- [ ] Achat serveur en cristaux
- [ ] Inventaire et équipement par emplacement
- [ ] Teinture
- [ ] Coupes de cheveux verrouillées

## Phase 8 — Quêtes, boss, donjons, classes
- [ ] Quête quotidienne générée par le serveur
- [ ] Quêtes hebdomadaires et d'événement
- [ ] Épreuves de rang (force, endurance, agilité), conditions d'accès, délai de 48 h
- [ ] Récompenses de boss (rang, titre, équipement exclusif, cinématique)
- [ ] Donjons hebdomadaires
- [ ] Classes (choix au rang C, changement mensuel)

## Phase 9 — Hauts faits, titres, auras, Ombres
- [ ] 60 hauts faits (7 catégories, dont secrets)
- [ ] Titres équipables
- [ ] Auras cosmétiques
- [ ] Ombres (extraction rang B+, bonus passif, limites 5/7)

## Phase 10 — Coach caméra
- [ ] Consentement et écran caméra
- [ ] Détection de pose ML Kit sur l'appareil
- [ ] Comptage pompes, squats, jumping jacks, fentes ; chrono planche ; amplitude
- [ ] Bonus +10 % et obligation pendant les boss compatibles
- [ ] Vérification : aucune image stockée ni transmise

## Phase 11 — Santé
- [ ] Health Connect / HealthKit en lecture seule
- [ ] Synchronisation serveur plafonnée (Endurance / Vitalité)
- [ ] Bonus sommeil ≥ 7 h
- [ ] Saisie manuelle de l'hydratation

## Phase 12 — Finitions et publication
- [ ] Sons et ambiance
- [ ] Performances (profilage, temps de démarrage)
- [ ] Audit d'accessibilité
- [ ] RGPD : export et suppression des données
- [ ] Textes du store et politique de confidentialité
- [ ] Builds de publication Android et iOS
- [ ] Relecture du référentiel anatomique par un coach diplômé ou un kinésithérapeute
