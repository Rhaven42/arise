# CLAUDE.md — ARISE

> Ce fichier fait foi pendant tout le projet. **Relis-le, ainsi que `docs/SPEC.md`, `docs/ANATOMY.md` et `docs/ROADMAP.md`, au début de chaque phase.**
>
> Depuis le 04/11/2026, ARISE est une application **100 % hors ligne** : ni compte, ni serveur, ni Firebase (SPEC.md §21).
>
> Depuis le 12/11/2026, le nom affiché aux utilisateurs est **Hero Protocol** (SPEC.md §35) ; « ARISE » / `arise` reste le nom de code interne.

## 1. Le projet en une phrase
ARISE est une application mobile de sport gamifiée (Android + iOS), dans l'esprit « chasseur qui s'éveille et monte en rang » : l'utilisateur fait du sport réel, gagne de l'expérience, monte de niveau, débloque des rangs et fait évoluer un avatar 3D personnalisable dans le royaume original d'**Arisia**.

- Ambiance : MMORPG fantasy héroïque — cadres de pierre et de bois, éclairage chaud, polices médiévales, fenêtres de « Système » qui annoncent quêtes et récompenses.
- **Aucun** nom, logo, personnage, modèle 3D ni asset protégé de Solo Leveling, de World of Warcraft (y compris `wow-model-viewer`, Wowhead ou des exports wow.export) ou de toute autre œuvre. Univers, noms et visuels 100 % originaux.

## 2. Langues
| Élément | Langue |
|---|---|
| Interface utilisateur (textes, libellés) | Français (via fichiers ARB / `flutter_localizations`, jamais de chaînes en dur dans les widgets) |
| Code, identifiants, noms de fichiers, clés JSON | Anglais |
| Commentaires de code | Français |
| Messages de commit | Français, format Conventional Commits (`feat:`, `fix:`, `test:`…) |

## 3. Stack technique — ne pas changer sans validation explicite
| Domaine | Choix |
|---|---|
| Framework | Flutter (canal stable), Dart null-safety, Android + iOS |
| État | Riverpod + `riverpod_generator` (`@riverpod`) |
| Navigation | `go_router` |
| Modèles | `freezed` + `json_serializable` |
| Données | **Drift (SQLite) sur l'appareil** : seule source de vérité |
| Sauvegarde | Export / import d'un fichier JSON (`share_plus`, `file_picker`) |
| Notifications | Notifications locales (ajoutées en phase 2) |
| Lecteur de séance | `audioplayers` (bips embarqués), `flutter_tts` (voix hors ligne), `wakelock_plus` (écran allumé) |
| Santé | package `health` (Health Connect Android, HealthKit iOS) — **lecture seule** |
| Avatar 3D | interface abstraite `CharacterRenderer` ; MVP = modèles `.glb` originaux ; Unity plus tard |
| Animations d'exercices | interface `ExerciseAnimationPlayer` (Rive ou `.glb` animés) |
| Heatmap musculaire | 2 silhouettes SVG (face / dos), une zone par muscle, identifiée par l'ID de `docs/ANATOMY.md` |

Retirés du projet : Firebase (Auth, Firestore, Functions, Storage, Messaging), connexion Google, coach caméra.

## 4. Architecture
Clean Architecture découpée par fonctionnalité.

```
lib/
  core/              # thème, design system, routeur, erreurs, base locale, utilitaires, constantes de jeu
    anatomy/                  # identifiants des muscles, silhouettes SVG, BodyMap
    config/game_config.dart   # TOUTES les constantes d'équilibrage
    database/                 # base Drift, tables, migrations
    design_system/
    router/
    errors/
    theme/
    utils/
  features/
    <feature>/
      domain/        # entités, value objects, interfaces de repository, use cases, RÈGLES DU JEU — aucune dépendance Flutter
      data/          # DTO, sources Drift, implémentations des repositories
      presentation/  # écrans, widgets, contrôleurs (Riverpod)
assets/              # svg/, animations/, models/, fonts/, sounds/
test/                # reflète exactement la structure de lib/
integration_test/    # parcours complets lancés sur émulateur Android en CI
docs/                # SPEC, ANATOMY, ROADMAP, ASSETS
```

### Fonctionnalités (`lib/features/`)
`onboarding`, `profile`, `backup`, `character_creation`, `avatar`, `exercises`, `planning`, `workout_player`, `progression`, `streaks`, `quests`, `trials` (épreuves), `shop`, `inventory`, `achievements` (hauts faits), `titles`, `muscle_analysis`, `health`, `shadows` (Ombres), `notifications`, `settings`.

### Règles de dépendance
- `domain` ne dépend de rien d'autre que Dart pur (+ `freezed`/`json_annotation` pour les entités).
- `data` dépend de `domain`. `presentation` dépend de `domain` (et de `data` uniquement via les providers d'injection).
- Une fonctionnalité n'importe jamais la couche `data` ni les écrans ou widgets d'une autre fonctionnalité. Elle peut utiliser son `domain` et ses providers publics d'injection (`*_providers.dart`, `*_controller.dart`). Seul le routeur assemble les écrans de plusieurs fonctionnalités.
- `CharacterRenderer` et `ExerciseAnimationPlayer` ne doivent jamais exposer de type propre à un moteur (glb, Unity, Rive) dans leur signature.

## 5. Règles impératives
1. **Les règles du jeu vivent dans le domaine.** Expérience, niveaux, rangs, stats, cristaux, séries de jours, boucliers, déblocages, récompenses, quêtes et agrégats musculaires sont calculés **uniquement** par des use cases purs de la couche `domain`. Les widgets et contrôleurs ne calculent rien : ils appellent les use cases et affichent le résultat.
2. **Constantes d'équilibrage centralisées** dans `lib/core/config/game_config.dart`, jamais écrites en dur ailleurs. Des tests de cohérence vérifient la configuration.
3. **Anatomie** : les correspondances muscle ↔ exercice proviennent **uniquement** de `docs/ANATOMY.md`. Ne jamais inventer de mapping.
4. **Zéro code à compléter, zéro TODO.** Chaque phase livrée compile, se lance, passe `flutter analyze` **sans avertissement** et est testée.
5. **Tests** : toute la logique de jeu a des tests unitaires ; les écrans clés ont des tests de widgets ; les migrations de la base sont testées ; chaque phase ajoute ou étend un parcours d'intégration sur émulateur.
6. **Processus par phase** : avant → plan court + attente de validation ; après → liste de ce qui est fait, comment le tester, limites, puis cocher `docs/ROADMAP.md`.
7. **Accessibilité** : tailles de police dynamiques (`textScaler` respecté), contrastes WCAG AA minimum, heatmap lisible par les daltoniens (motif + libellé en plus de la couleur), `Semantics` sur les éléments interactifs.
8. **Santé** : aucune mécanique ne pousse au surentraînement. Le repos est respecté et valorisé. Avertissement affiché en cas de douleur ou de fatigue extrême ; plafond de 120 min d'effort actif par jour (XP divisée par deux au-delà + message de prudence).
9. **Assets 3D de substitution** : deux mannequins **distincts** homme / femme (topologies différentes), jamais de cubes ni d'un modèle unique redimensionné, jamais d'assets tiers protégés. Tout ce que l'artiste 3D devra fournir est documenté dans `docs/ASSETS.md`.
10. **Données de l'utilisateur** : elles ne quittent jamais le téléphone, sauf par un export qu'il déclenche lui-même. Toute évolution du schéma Drift s'accompagne d'une migration testée et d'une compatibilité ascendante du format de sauvegarde.

## 6. Conventions de code
- Lint strict, zéro avertissement toléré (`analysis_options.yaml`).
- Fichiers en `snake_case.dart`, classes en `PascalCase`, providers générés en `camelCaseProvider`.
- Entités `freezed` immuables ; pas de logique métier dans les widgets.
- Les erreurs passent par un type `Failure` typé (`core/errors`), jamais d'exception brute remontée à l'UI.
- Les dates sont stockées en UTC ; les bornes de jour se calculent dans le fuseau horaire du téléphone, à minuit heure locale.
- Les identifiants de muscles, d'exercices, d'objets et de hauts faits sont des chaînes stables en `snake_case` anglais.
- Code généré (`*.g.dart`, `*.freezed.dart`) non modifié à la main.

## 7. Données
- Toutes les données sont dans la base Drift `arise` (fichier SQLite de l'application).
- Le fichier de sauvegarde est un JSON versionné (`format: "arise-backup"`, `version`) ; un import valide remplace intégralement les données locales après confirmation.
- Paramètres : effacement complet des données sur demande, avec confirmation.

## 8. Outils et commandes
Versions : Flutter 3.47 / Dart 3.13.

| Action | Commande |
|---|---|
| Dépendances | `flutter pub get` |
| Traductions (ARB → `lib/l10n/generated/`) | `flutter gen-l10n` |
| Code généré (freezed, riverpod, drift) | `dart run build_runner build --delete-conflicting-outputs` |
| Analyse | `flutter analyze --fatal-infos --fatal-warnings` |
| Tests | `flutter test` |
| Parcours sur appareil | `flutter test integration_test` |

- Les fichiers générés (`*.g.dart`, `*.freezed.dart`, `lib/l10n/generated/`) ne sont pas versionnés : la CI les régénère.
- Ajout ou retrait de dépendances : workflow GitHub `deps` (lancé avec la liste des paquets), qui committe `pubspec.yaml` et `pubspec.lock`.
- Formatage : `dart format` est appliqué par la CI ; sur une branche de travail, elle committe le résultat (« style: formatage automatique ») — faire `git pull` avant de continuer.
- Outils de création des contenus (hors application) : les silhouettes SVG, les poses d'animation et le catalogue sont générés par des scripts Python versionnés dans `tool/` ; le catalogue relit les muscles dans ANATOMY.md.
- CI : `.github/workflows/ci.yml` (analyse, absence de TODO, tests, APK de debug en artefact, parcours d'intégration sur émulateur Android).

## 9. Choix techniques
- Lint : `very_good_analysis` 11, avec deux règles désactivées : `public_member_api_docs` (pas de doc obligatoire sur chaque membre) et `unnecessary_type_name_in_constructor` (on garde la syntaxe classique des constructeurs, compatible avec freezed et drift).
- Typographie : Cinzel pour les titres et les boutons, IM Fell English pour les textes d'ambiance, police du système pour le corps de texte (lisibilité).
- Le routeur (`core/router`) est la racine de composition de la navigation : il est le seul élément de `core` autorisé à importer des écrans de fonctionnalités.
- Les dossiers de fonctionnalités sont créés au fil des phases (Git ne versionne pas les dossiers vides).
- `.claude/` contient des extraits d'ECC (licence MIT) pour Flutter / Dart : compétences, agents de relecture et règles. Voir `.claude/ECC.md` ; ce fichier-ci l'emporte en cas de désaccord.
