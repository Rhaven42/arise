import 'package:arise/app.dart';
import 'package:arise/core/config/app_environment.dart';
import 'package:arise/core/firebase/firebase_bootstrap.dart';
import 'package:arise/core/utils/licenses.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  await initializeFirebase(AppEnvironment.fromDefines());
  runApp(const ProviderScope(child: AriseApp()));
}
