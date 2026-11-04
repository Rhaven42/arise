# CLAUDE.md — ARISE

> Ce fichier fait foi pendant tout le projet. **Relis-le, ainsi que `docs/SPEC.md`, `docs/ANATOMY.md` et `docs/ROADMAP.md`, au début de chaque phase.**

## 1. Le projet en une phrase
ARISE est une application mobile de sport gamifiée (Android + iOS), dans l'esprit « chasseur qui s'éveille et monte en rang » : l'utilisateur fait du sport réel, gagne de l'expérience, monte de niveau, débloque des rangs et fait évoluer un avatar 3D personnalisable dans le royaume original d'**Arisia**.

- Ambiance : MMORPG fantasy héroïque — cadres de pierre et de bois, éclairage chaud, polices médiévales, fenêtres de « Système » qui annoncent quêtes et récompenses.
- **Aucun** nom, logo, personnage ni asset protégé de Solo Leveling ou de World of Warcraft. Univers, noms et visuels 100 % originaux.

## 2. Langues
| Élément | Langue |
|---|---|
| Interface utilisateur (textes, libellés) | Français (via fichiers ARB / `flutter_localizations`, jamais de chaînes en dur dans les widgets) |
| Code, identifiants, noms de fichiers, clés Firestore | Anglais |
| Commentaires de code | Français |
| Messages de commit | Français, format Conventional Commits (`feat:`, `fix:`, `test:`…) |

## 3. Stack technique — ne pas changer sans validation explicite
| Domaine | Choix |
|---|---|
| Framework | Flutter (canal stable), Dart null-safety, Android + iOS |
| État | Riverpod + `riverpod_generator` (`@riverpod`) |
| Navigation | `go_router` |
| Modèles | `freezed` + `json_serializable` |
| Auth | Firebase Auth + Google Sign-In |
| Base distante | Cloud Firestore |
| Logique serveur | Cloud Functions, TypeScript, Node 20 |
| Fichiers | Firebase Storage |
| Notifications push | Firebase Cloud Messaging |
| Local / hors ligne | Drift (SQLite) — séances en attente de synchronisation, brouillons |
| Santé | package `health` (Health Connect Android, HealthKit iOS) — **lecture seule** |
| Caméra | package `camera` + ML Kit Pose Detection, **100 % sur l'appareil** |
| Avatar 3D | interface abstraite `CharacterRenderer` ; MVP = modèles `.glb` ; Unity plus tard |
| Animations d'exercices | interface `ExerciseAnimationPlayer` (Rive ou `.glb` animés) |
| Heatmap musculaire | 2 silhouettes SVG (face / dos), une zone par muscle, identifiée par l'ID de `docs/ANATOMY.md` |

## 4. Architecture
Clean Architecture découpée par fonctionnalité.

```
lib/
  core/              # thème, design system, routeur, erreurs, utilitaires, constantes de jeu
    config/game_config.dart   # TOUTES les constantes d'équilibrage côté client
    design_system/
    router/
    errors/
    theme/
    utils/
  features/
    <feature>/
      domain/        # entités, value objects, interfaces de repository, use cases — AUCUNE dépendance Flutter
      data/          # DTO, sources Firestore et Drift, implémentations des repositories
      presentation/  # écrans, widgets, contrôleurs (Riverpod)
functions/           # Cloud Functions TypeScript (Node 20)
  src/config/gameConfig.ts    # miroir exact de game_config.dart
assets/              # svg/, animations/, models/, fonts/, sounds/
test/                # reflète exactement la structure de lib/
docs/                # SPEC, ANATOMY, ROADMAP, ASSETS
```

### Fonctionnalités (`lib/features/`)
`auth`, `onboarding`, `character_creation`, `avatar`, `exercises`, `planning`, `workout_player`, `progression`, `streaks`, `quests`, `trials` (épreuves), `shop`, `inventory`, `achievements` (hauts faits), `titles`, `muscle_analysis`, `health`, `camera_coach`, `shadows` (Ombres), `notifications`, `settings`.

### Règles de dépendance
- `domain` ne dépend de rien d'autre que Dart pur (+ `freezed` pour les entités).
- `data` dépend de `domain`. `presentation` dépend de `domain` (et de `data` uniquement via les providers d'injection).
- Une fonctionnalité n'importe jamais la couche `data` ou `presentation` d'une autre fonctionnalité ; elle passe par son `domain` ou par `core`.
- `CharacterRenderer` et `ExerciseAnimationPlayer` ne doivent jamais exposer de type propre à un moteur (glb, Unity, Rive) dans leur signature.

## 5. Règles impératives
1. **Le serveur fait autorité.** Expérience, niveaux, rangs, stats calculées, cristaux, séries de jours, boucliers, déblocages, récompenses, inventaire, hauts faits, quêtes et agrégats musculaires sont calculés **uniquement** dans les Cloud Functions. Les règles Firestore interdisent au client d'écrire ces champs. Le client peut afficher des estimations, jamais les persister.
2. **Constantes d'équilibrage centralisées** : `lib/core/config/game_config.dart` et `functions/src/config/gameConfig.ts`. Valeurs identiques, vérifiées par un **test de parité** (export JSON canonique des deux côtés comparé en CI).
3. **Anatomie** : les correspondances muscle ↔ exercice proviennent **uniquement** de `docs/ANATOMY.md`. Ne jamais inventer de mapping.
4. **Zéro code à compléter, zéro TODO.** Chaque phase livrée compile, se lance, passe `flutter analyze` / `eslint` **sans avertissement** et est testée.
5. **Tests** : toute la logique de jeu a des tests unitaires (client et serveur) ; les écrans clés ont des tests de widgets. Règles Firestore testées avec l'émulateur.
6. **Processus par phase** : avant → plan court + attente de validation ; après → liste de ce qui est fait, comment le tester, limites, puis cocher `docs/ROADMAP.md`.
7. **Accessibilité** : tailles de police dynamiques (`textScaler` respecté), contrastes WCAG AA minimum, heatmap lisible par les daltoniens (motif + libellé en plus de la couleur), `Semantics` sur les éléments interactifs.
8. **Santé** : aucune mécanique ne pousse au surentraînement. Le repos est respecté et valorisé. Avertissement affiché en cas de douleur ou de fatigue extrême ; plafond de 120 min d'effort actif par jour (XP divisée par deux au-delà + message de prudence).
9. **Assets 3D de substitution** : deux mannequins **distincts** homme / femme (topologies différentes), jamais de cubes ni d'un modèle unique redimensionné. Tout ce que l'artiste 3D devra fournir est documenté dans `docs/ASSETS.md`.

## 6. Conventions de code
- Lint strict, zéro avertissement toléré (configuration dans `analysis_options.yaml`, à valider en phase 0).
- Fichiers en `snake_case.dart`, classes en `PascalCase`, providers générés en `camelCaseProvider`.
- Entités `freezed` immuables ; pas de logique métier dans les widgets.
- Les erreurs passent par un type `Failure` typé (`core/errors`), jamais d'exception brute remontée à l'UI.
- Les dates sont stockées en UTC ; le fuseau horaire IANA de l'utilisateur est stocké dans son profil et utilisé côté serveur pour les bornes de jour.
- Les identifiants de muscles, d'exercices, d'objets et de hauts faits sont des chaînes stables en `snake_case` anglais.
- Les nombres d'équilibrage ne sont **jamais** écrits en dur ailleurs que dans les fichiers de configuration de jeu.
- Code généré (`*.g.dart`, `*.freezed.dart`) non modifié à la main.

## 7. Données et sécurité (résumé — détail dans SPEC.md §15)
- Écriture client autorisée : profil (champs non sensibles), personnage (apparence, équipement porté parmi l'inventaire possédé — vérifié par règle), séances (création uniquement), programmes, exercices personnalisés, préférences.
- Écriture serveur seulement : `progression`, `inventory`, `achievements`, `quests`, `muscleAggregates`, `trials`, `shadows`, réservations de noms.
- Catalogues (`exercises`, `items`, `achievementsCatalog`, `trialsCatalog`) : lecture seule pour tous.
- Caméra : aucune image stockée ni envoyée ; seul le nombre de répétitions validées est transmis.

## 8. Outils et commandes (à compléter en phase 0 avec les commandes réelles)
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter analyze` / `flutter test`
- `cd functions && npm run lint && npm test`
- `firebase emulators:start` (Auth, Firestore, Functions, Storage)
