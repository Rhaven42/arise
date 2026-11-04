import 'package:arise/core/config/app_environment.dart';
import 'package:arise/core/firebase/demo_firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Initialise Firebase et, si demandé, branche les émulateurs locaux.
Future<void> initializeFirebase(AppEnvironment environment) async {
  await Firebase.initializeApp(options: DemoFirebaseOptions.currentPlatform);

  if (!environment.useFirebaseEmulators) {
    return;
  }

  final host = environment.emulatorHost;
  await FirebaseAuth.instance.useAuthEmulator(
    host,
    AppEnvironment.authEmulatorPort,
  );
  FirebaseFirestore.instance.useFirestoreEmulator(
    host,
    AppEnvironment.firestoreEmulatorPort,
  );
  await FirebaseStorage.instance.useStorageEmulator(
    host,
    AppEnvironment.storageEmulatorPort,
  );
}
