import 'package:flutter/foundation.dart';

/// Paramètres d'exécution, fournis par `--dart-define`.
///
/// - `USE_FIREBASE_EMULATORS` : `true` par défaut en debug.
/// - `FIREBASE_EMULATOR_HOST` : `10.0.2.2` par défaut (émulateur Android) ;
///   indiquer l'IP du poste pour un téléphone réel.
class AppEnvironment {
  const AppEnvironment({
    required this.useFirebaseEmulators,
    required this.emulatorHost,
  });

  factory AppEnvironment.fromDefines() => const AppEnvironment(
    useFirebaseEmulators: bool.fromEnvironment(
      'USE_FIREBASE_EMULATORS',
      defaultValue: kDebugMode,
    ),
    emulatorHost: String.fromEnvironment(
      'FIREBASE_EMULATOR_HOST',
      defaultValue: '10.0.2.2',
    ),
  );

  final bool useFirebaseEmulators;
  final String emulatorHost;

  static const authEmulatorPort = 9099;
  static const firestoreEmulatorPort = 8080;
  static const storageEmulatorPort = 9199;
}
