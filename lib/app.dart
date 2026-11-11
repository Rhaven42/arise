import 'dart:async';

import 'package:arise/core/audio/music.dart';
import 'package:arise/core/router/app_router.dart';
import 'package:arise/core/theme/arise_theme.dart';
import 'package:arise/features/planning/presentation/planning_providers.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Racine de l'application.
class AriseApp extends ConsumerStatefulWidget {
  const AriseApp({super.key});

  @override
  ConsumerState<AriseApp> createState() => _AriseAppState();
}

class _AriseAppState extends ConsumerState<AriseApp> {
  GoRouter? _router;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    // Musique en pause quand l'application passe en arrière-plan.
    _lifecycle = AppLifecycleListener(
      onHide: () => unawaited(ref.read(musicPlayerProvider).pause()),
      onShow: () => unawaited(ref.read(musicPlayerProvider).resume()),
    );
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRoute);
    _lifecycle?.dispose();
    super.dispose();
  }

  /// La musique suit l'écran affiché (titre, Système, boutique, séance).
  void _onRoute() {
    final router = _router;
    if (router == null) return;
    final location = router.routerDelegate.currentConfiguration.uri.path;
    unawaited(ref.read(musicPlayerProvider).play(musicForLocation(location)));
  }

  void _attach(GoRouter router) {
    if (identical(router, _router)) return;
    _router?.routerDelegate.removeListener(_onRoute);
    _router = router..routerDelegate.addListener(_onRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onRoute());
  }

  @override
  Widget build(BuildContext context) {
    // Garde les rappels du planning à jour pendant toute la session.
    ref
      ..listen(reminderSyncProvider, (_, _) {})
      // Réglage « Musique » du joueur.
      ..listen(playerProfileProvider, (_, next) {
        ref
            .read(musicPlayerProvider)
            .setEnabled(enabled: next.value?.music ?? true);
      });
    final router = ref.watch(appRouterProvider);
    _attach(router);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AriseTheme.dark(),
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
