# ARISE

Application mobile de sport gamifiée (Android et iOS) se déroulant dans le royaume d'Arisia. Le sport réel fait gagner de l'expérience, monter de niveau et de rang, et évoluer un avatar.

La documentation de référence se trouve dans [`CLAUDE.md`](CLAUDE.md) et dans `docs/` ([spécification](docs/SPEC.md), [référentiel anatomique](docs/ANATOMY.md), [feuille de route](docs/ROADMAP.md)).

## Prérequis

- Flutter 3.47 (canal stable) et Dart 3.13
- Node 20, et Java 21 pour les émulateurs Firebase
- Firebase CLI (`npm i -g firebase-tools`) ; aucun projet Firebase réel n'est nécessaire en développement (projet `demo-arise`)

## Lancer l'application

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs

# Dans un autre terminal : émulateurs Firebase (Auth, Firestore, Functions, Storage)
npm --prefix functions ci && npm --prefix functions run build
firebase emulators:start

# Émulateur Android (les émulateurs Firebase sont joints via 10.0.2.2)
flutter run
# Téléphone réel sur le même Wi-Fi : indiquer l'IP du poste
flutter run --dart-define=FIREBASE_EMULATOR_HOST=192.168.1.20
```

Sans émulateurs Firebase lancés, l'application démarre quand même : l'accueil et la page du design system fonctionnent hors ligne.

## Vérifications (identiques à la CI)

```bash
flutter analyze --fatal-infos --fatal-warnings
flutter test

cd functions
npm run lint && npm run typecheck && npm test
cd ..
firebase emulators:exec --only firestore --project demo-arise "npm --prefix functions run test:rules"
```

Chaque envoi sur GitHub déclenche la CI, qui produit aussi un APK de debug téléchargeable dans l'onglet *Actions* (artefact `arise-debug-apk`).
