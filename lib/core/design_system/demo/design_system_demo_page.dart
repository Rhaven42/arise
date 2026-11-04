import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/rank_badge.dart';
import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/design_system/widgets/system_window.dart';
import 'package:arise/core/design_system/widgets/xp_bar.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/theme/arise_typography.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Page de démonstration de tous les éléments du design system.
class DesignSystemDemoPage extends StatelessWidget {
  const DesignSystemDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final swatches = <(String, Color)>[
      (l10n.colorAbyss, AriseColors.abyss),
      (l10n.colorStone, AriseColors.stone),
      (l10n.colorWood, AriseColors.wood),
      (l10n.colorGold, AriseColors.gold),
      (l10n.colorEmber, AriseColors.ember),
      (l10n.colorParchment, AriseColors.parchment),
      (l10n.colorMana, AriseColors.mana),
      (l10n.colorDanger, AriseColors.danger),
      (l10n.colorSuccess, AriseColors.success),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.designSystemTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AriseSpacing.md),
        children: [
          _Section(
            title: l10n.designSystemColors,
            child: Wrap(
              spacing: AriseSpacing.sm,
              runSpacing: AriseSpacing.sm,
              children: [
                for (final (name, color) in swatches)
                  _Swatch(name: name, color: color),
              ],
            ),
          ),
          _Section(
            title: l10n.designSystemTypography,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.typographyDisplaySample,
                  style: textTheme.displaySmall,
                ),
                Text(l10n.typographyTitleSample, style: textTheme.titleLarge),
                const SizedBox(height: AriseSpacing.sm),
                Text(l10n.typographyBodySample, style: textTheme.bodyLarge),
                const SizedBox(height: AriseSpacing.sm),
                Text(
                  l10n.typographyFlavorSample,
                  style: AriseTypography.flavorStyle,
                ),
              ],
            ),
          ),
          _Section(
            title: l10n.designSystemButtons,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AriseButton(
                  label: l10n.buttonPrimarySample,
                  icon: Icons.shield_outlined,
                  onPressed: () {},
                ),
                const SizedBox(height: AriseSpacing.sm),
                AriseButton(
                  label: l10n.buttonSecondarySample,
                  variant: AriseButtonVariant.secondary,
                  onPressed: () {},
                ),
                const SizedBox(height: AriseSpacing.sm),
                AriseButton(label: l10n.buttonDisabledSample, onPressed: null),
              ],
            ),
          ),
          _Section(
            title: l10n.designSystemFrames,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StoneFrame(child: Text(l10n.frameStoneSample)),
                const SizedBox(height: AriseSpacing.md),
                StoneFrame(
                  material: FrameMaterial.wood,
                  child: Text(l10n.frameWoodSample),
                ),
              ],
            ),
          ),
          _Section(
            title: l10n.designSystemSystemWindow,
            child: SystemWindow(
              header: l10n.systemWindowHeader,
              title: l10n.sampleQuestTitle,
              actions: [
                AriseButton(
                  label: l10n.buttonSecondarySample,
                  variant: AriseButtonVariant.secondary,
                  onPressed: () {},
                ),
                AriseButton(label: l10n.buttonPrimarySample, onPressed: () {}),
              ],
              child: Text(l10n.sampleQuestBody, style: textTheme.bodyLarge),
            ),
          ),
          _Section(
            title: l10n.designSystemProgress,
            child: const XpBar(current: 63, goal: 180),
          ),
          _Section(
            title: l10n.designSystemRanks,
            child: Wrap(
              spacing: AriseSpacing.md,
              runSpacing: AriseSpacing.md,
              children: [
                for (final rank in RankId.values) RankBadge(rank: rank),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AriseSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: AriseColors.gold),
            ),
          ),
          const Divider(height: AriseSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Column(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: AriseColors.woodLight),
              borderRadius: BorderRadius.circular(AriseSpacing.radius),
            ),
          ),
          const SizedBox(height: AriseSpacing.xs),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
