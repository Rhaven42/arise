import 'package:arise/core/router/app_router.dart';
import 'package:arise/core/theme/arise_theme.dart';
import 'package:arise/features/planning/presentation/planning_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Racine de l'application.
class AriseApp extends ConsumerWidget {
  const AriseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garde les rappels du planning à jour pendant toute la session.
    ref.listen(reminderSyncProvider, (_, _) {});
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AriseTheme.dark(),
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
