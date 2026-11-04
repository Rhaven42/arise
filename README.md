# ARISE

Application mobile de sport gamifiée (Android et iOS) se déroulant dans le royaume d'Arisia. Le sport réel fait gagner de l'expérience, monter de niveau et de rang, et évoluer un avatar.

ARISE fonctionne **100 % hors ligne** : aucun compte, aucun serveur, toutes les données restent sur le téléphone (sauvegarde par export / import d'un fichier).

La documentation de référence se trouve dans [`CLAUDE.md`](CLAUDE.md) et dans `docs/` ([spécification](docs/SPEC.md), [référentiel anatomique](docs/ANATOMY.md), [feuille de route](docs/ROADMAP.md)).

## Installer la dernière version (Android)

Onglet **Actions** du dépôt → dernier passage vert du workflow `ci` → artefact `arise-debug-apk` → installer l'APK sur le téléphone (autoriser l'installation hors Play Store).

## Lancer depuis un ordinateur

Prérequis : Flutter 3.47 (canal stable).

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Vérifications (identiques à la CI)

```bash
flutter analyze --fatal-infos --fatal-warnings
flutter test
flutter test integration_test/app_launch_test.dart   # sur un émulateur ou un téléphone branché
```

Le workflow `screenshots` (lancement manuel) produit des captures d'écran de tout le parcours sur un émulateur Android.
