import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/design_system/widgets/system_window.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/progression/domain/hero_class.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Choix de la classe (SPEC §6) : rang C requis, un changement par mois.
class HeroClassPage extends ConsumerWidget {
  const HeroClassPage({super.key});

  static Key selectKey(HeroClass heroClass) =>
      Key('class-select-${heroClass.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(progressionControllerProvider).value?.state;
    final now = ref.watch(clockProvider)();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.classTitle)),
      body: state == null
          ? const Center(
              child: CircularProgressIndicator(color: AriseColors.gold),
            )
          : ListView(
              padding: const EdgeInsets.all(AriseSpacing.md),
              children: [
                SystemWindow(
                  header: l10n.systemWindowHeader,
                  title: switch (state.heroClass) {
                    final current? => l10n.classCurrent(
                      l10n.className(current.name),
                    ),
                    null => l10n.classNone,
                  },
                  child: Text(l10n.classPageIntro, style: textTheme.bodyLarge),
                ),
                if (nextClassChangeAt(state) case final next?
                    when now.isBefore(next)) ...[
                  const SizedBox(height: AriseSpacing.sm),
                  Text(
                    l10n.classCooldown(
                      DateFormat.yMMMMd('fr').format(next.toLocal()),
                    ),
                    style: textTheme.bodyMedium,
                  ),
                ],
                for (final heroClass in HeroClass.values) ...[
                  const SizedBox(height: AriseSpacing.md),
                  _ClassCard(heroClass: heroClass, state: state, now: now),
                ],
              ],
            ),
    );
  }
}

class _ClassCard extends ConsumerWidget {
  const _ClassCard({
    required this.heroClass,
    required this.state,
    required this.now,
  });

  final HeroClass heroClass;
  final ProgressionState state;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final name = l10n.className(heroClass.name);
    final issue = classChoiceIssue(state, heroClass, now: now);
    final current = state.heroClass == heroClass;
    return StoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            name,
            style: textTheme.titleLarge?.copyWith(
              color: current ? AriseColors.goldBright : AriseColors.gold,
            ),
          ),
          const SizedBox(height: AriseSpacing.xs),
          Text(
            l10n.classDescription(heroClass.name),
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: AriseSpacing.sm),
          AriseButton(
            key: HeroClassPage.selectKey(heroClass),
            label: l10n.classSelect(name),
            variant: current
                ? AriseButtonVariant.secondary
                : AriseButtonVariant.primary,
            onPressed: issue != null
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final refused = await ref
                        .read(progressionControllerProvider.notifier)
                        .chooseHeroClass(heroClass);
                    messenger
                      ..removeCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            refused == null
                                ? l10n.classChosen(name)
                                : l10n.classChoiceIssue(refused.name),
                          ),
                        ),
                      );
                  },
          ),
        ],
      ),
    );
  }
}
