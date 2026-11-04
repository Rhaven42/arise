import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/planning/domain/program_rules.dart';
import 'package:arise/features/planning/presentation/planning_labels.dart';
import 'package:arise/features/planning/presentation/planning_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Liste des programmes du joueur.
class ProgramsPage extends ConsumerWidget {
  const ProgramsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final programs = ref.watch(programsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.programsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.programNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.programCreate),
      ),
      body: switch (programs) {
        AsyncData(:final value) when value.isEmpty => Center(
          child: Padding(
            padding: const EdgeInsets.all(AriseSpacing.lg),
            child: Text(l10n.programsEmpty, textAlign: TextAlign.center),
          ),
        ),
        AsyncData(:final value) => ListView.separated(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: value.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final program = value[index];
            final duration = estimateDuration(program);
            return ListTile(
              title: Text(program.name),
              subtitle: Text(
                [
                  l10n.format(program.format),
                  l10n.programExerciseCount(program.items.length),
                  if (duration != null) l10n.duration(duration),
                ].join(' · '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.programEdit(program.id)),
            );
          },
        ),
        AsyncError() => Center(child: Text(l10n.errorGeneric)),
        _ => const Center(
          child: CircularProgressIndicator(color: AriseColors.gold),
        ),
      },
    );
  }
}
