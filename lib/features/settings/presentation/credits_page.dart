import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/settings/domain/credits.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Crédits : auteurs des ressources tierces et licences.
class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(
        top: AriseSpacing.lg,
        bottom: AriseSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: textTheme.titleMedium?.copyWith(color: AriseColors.gold),
        ),
      ),
    );
    Widget entry(Credit credit) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AriseSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.creditsEntry(credit.work, credit.author),
            style: textTheme.bodyLarge,
          ),
          Text(
            l10n.creditsLicense(credit.license.name, credit.source),
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.creditsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AriseSpacing.md),
        children: [
          Text(l10n.creditsIntro, style: textTheme.bodyLarge),
          section(l10n.creditsCcBySection),
          for (final credit in ccByCredits) entry(credit),
          section(l10n.creditsOtherSection),
          for (final credit in otherCredits) entry(credit),
        ],
      ),
    );
  }
}
