import 'package:arise/core/theme/arise_theme.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpProviderApp on WidgetTester {
  /// Affiche [widget] dans un `ProviderScope` relié à [container].
  Future<void> pumpWithContainer(ProviderContainer container, Widget widget) {
    return pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AriseTheme.dark(),
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: widget,
        ),
      ),
    );
  }
}
