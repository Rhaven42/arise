import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Options d'un projet Firebase de démonstration (`demo-arise`).
///
/// Les projets dont l'identifiant commence par `demo-` fonctionnent
/// uniquement avec les émulateurs locaux, sans projet réel. Elles seront
/// remplacées par les options générées par `flutterfire configure` lorsque
/// le projet Firebase de production sera créé.
abstract final class DemoFirebaseOptions {
  static const projectId = 'demo-arise';

  static FirebaseOptions get currentPlatform {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
        'ARISE ne cible que Android et iOS.',
      ),
    };
  }

  static const android = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: projectId,
    storageBucket: '$projectId.appspot.com',
  );

  static const ios = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: projectId,
    storageBucket: '$projectId.appspot.com',
    iosBundleId: 'fr.arisia.arise',
  );
}
