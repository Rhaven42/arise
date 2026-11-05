import 'package:arise/core/anatomy/body_map.dart';
import 'package:arise/core/anatomy/heat_level.dart';
import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/design_system/widgets/system_window.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/exercises/presentation/exercise_labels.dart';
import 'package:arise/features/muscle_analysis/domain/analysis_period.dart';
import 'package:arise/features/muscle_analysis/domain/muscle_report.dart';
import 'package:arise/features/muscle_analysis/presentation/muscle_analysis_providers.dart';
import 'package:arise/features/progression/presentation/progression_labels.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Analyse musculaire : heatmap par période, conseils et déséquilibres.
class MuscleAnalysisPage extends ConsumerStatefulWidget {
  const MuscleAnalysisPage({super.key});

  @override
  ConsumerState<MuscleAnalysisPage> createState() => _MuscleAnalysisPageState();
}

class _MuscleAnalysisPageState extends ConsumerState<MuscleAnalysisPage> {
  MuscleId? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(analysisRangeProvider);
    final controller = ref.read(analysisRangeProvider.notifier);
    final report = ref.watch(muscleReportProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.analysisTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AriseSpacing.md),
        children: [
          SegmentedButton<AnalysisPeriod>(
            segments: [
              for (final period in AnalysisPeriod.values)
                ButtonSegment(
                  value: period,
                  label: Text(l10n.analysisPeriod(period.name)),
                ),
            ],
            selected: {range.period},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              controller.select(selection.first);
              setState(() => _selected = null);
            },
          ),
          const SizedBox(height: AriseSpacing.sm),
          Row(
            children: [
              IconButton(
                tooltip: l10n.analysisPrevious,
                icon: const Icon(Icons.chevron_left),
                onPressed: controller.previous,
              ),
              Expanded(
                child: Text(
                  _rangeLabel(l10n, range),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: AriseColors.gold),
                ),
              ),
              IconButton(
                tooltip: l10n.analysisNext,
                icon: const Icon(Icons.chevron_right),
                onPressed: controller.canGoNext ? controller.next : null,
              ),
            ],
          ),
          switch (report) {
            AsyncData(:final value) => _ReportBody(
              report: value,
              selected: _selected,
              onMuscleTap: (muscle) => setState(() => _selected = muscle),
            ),
            AsyncError() => Text(l10n.errorGeneric),
            _ => const Padding(
              padding: EdgeInsets.all(AriseSpacing.xl),
              child: Center(
                child: CircularProgressIndicator(color: AriseColors.gold),
              ),
            ),
          },
        ],
      ),
    );
  }

  String _rangeLabel(AppLocalizations l10n, PeriodRange range) {
    if (range.period == AnalysisPeriod.day) return formatCivilDate(range.start);
    return l10n.analysisRangeSpan(
      formatCivilDate(range.start),
      formatCivilDate(range.end.previous),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({
    required this.report,
    required this.selected,
    required this.onMuscleTap,
  });

  final MuscleReport report;
  final MuscleId? selected;
  final ValueChanged<MuscleId> onMuscleTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final dayView = report.range.period == AnalysisPeriod.day;

    String valueLine(MuscleId muscle) => l10n.analysisMuscleValue(
      l10n.muscle(muscle),
      _formatValue(report.values[muscle] ?? 0),
      l10n.heatLevelName(report.levels[muscle]!.name),
    );

    String semantics(BodyView view) => l10n.analysisHeatSemantics(
      view.name,
      [
        for (final muscle in MuscleId.values)
          if (muscle.view == view) valueLine(muscle),
      ].join('. '),
    );

    final selectedMuscle = selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          dayView ? l10n.analysisUnitDaily : l10n.analysisUnitWeekly,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall,
        ),
        Text(
          l10n.analysisSessions(report.sessionCount),
          textAlign: TextAlign.center,
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AriseSpacing.sm),
        Row(
          children: [
            for (final view in BodyView.values)
              Expanded(
                child: Column(
                  children: [
                    Text(l10n.bodyViewLabel(view.name)),
                    const SizedBox(height: AriseSpacing.xs),
                    SizedBox(
                      height: 300,
                      child: BodyMap(
                        view: view,
                        heat: report.levels,
                        semanticLabel: semantics(view),
                        onMuscleTap: onMuscleTap,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (selectedMuscle != null)
          Padding(
            padding: const EdgeInsets.only(top: AriseSpacing.sm),
            child: Text(
              valueLine(selectedMuscle),
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
          ),
        const SizedBox(height: AriseSpacing.md),
        const _HeatLegend(),
        const SizedBox(height: AriseSpacing.lg),
        if (report.alerts.isNotEmpty) ...[
          for (final alert in report.alerts)
            Padding(
              padding: const EdgeInsets.only(bottom: AriseSpacing.sm),
              child: _AlertBox(text: _alertText(l10n, alert)),
            ),
        ],
        SystemWindow(
          header: l10n.systemWindowHeader,
          title: l10n.analysisSuggestionsTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (report.suggestions.isEmpty)
                Text(
                  report.sessionCount == 0
                      ? l10n.analysisSessions(0)
                      : l10n.analysisNoSuggestion,
                  style: textTheme.bodyLarge,
                )
              else
                for (final suggestion in report.suggestions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AriseSpacing.xs),
                    child: Text(
                      l10n.analysisSuggestion(
                        l10n.muscle(suggestion.muscle),
                        suggestion.exercise.name,
                      ),
                      style: textTheme.bodyLarge,
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: AriseSpacing.md),
        StoneFrame(
          material: FrameMaterial.wood,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.analysisFlexibility(report.flexibilityMinutes),
                style: textTheme.titleMedium,
              ),
              Text(l10n.analysisFlexibilityHint, style: textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: AriseSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            l10n.analysisMusclesTitle,
            style: textTheme.headlineSmall?.copyWith(color: AriseColors.gold),
          ),
        ),
        const SizedBox(height: AriseSpacing.sm),
        for (final muscle in report.musclesByVolume)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                _Swatch(level: report.levels[muscle]!),
                const SizedBox(width: AriseSpacing.sm),
                Expanded(
                  child: Text(valueLine(muscle), style: textTheme.bodyMedium),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _alertText(AppLocalizations l10n, ImbalanceAlert alert) {
    final ratio = alert.ratio.isFinite
        ? alert.ratio.toStringAsFixed(1).replaceAll('.', ',')
        : '∞';
    return switch (alert.kind) {
      ImbalanceKind.frontBack => l10n.analysisAlertFrontBack(
        alert.dominantIsFirst ? 'front' : 'back',
        ratio,
      ),
      ImbalanceKind.pushPull => l10n.analysisAlertPushPull(
        alert.dominantIsFirst ? 'push' : 'pull',
        ratio,
      ),
    };
  }
}

/// Valeur arrondie au dixième, avec une virgule.
String _formatValue(double value) {
  final rounded = (value * 10).round() / 10;
  final text = rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);
  return text.replaceAll('.', ',');
}

class _HeatLegend extends StatelessWidget {
  const _HeatLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: AriseSpacing.md,
      runSpacing: AriseSpacing.sm,
      children: [
        for (final level in HeatLevel.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Swatch(level: level),
              const SizedBox(width: AriseSpacing.xs),
              Text(
                l10n.heatLevelName(level.name),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.level});

  final HeatLevel level;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 20,
      child: CustomPaint(painter: _SwatchPainter(level)),
    );
  }
}

class _SwatchPainter extends CustomPainter {
  const _SwatchPainter(this.level);

  final HeatLevel level;

  @override
  void paint(Canvas canvas, Size size) {
    paintHeatZone(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
      ),
      level,
    );
  }

  @override
  bool shouldRepaint(covariant _SwatchPainter oldDelegate) =>
      oldDelegate.level != level;
}

class _AlertBox extends StatelessWidget {
  const _AlertBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AriseColors.stoneDark,
        border: Border.all(color: AriseColors.heatSome, width: 1.5),
        borderRadius: BorderRadius.circular(AriseSpacing.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AriseSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.balance, color: AriseColors.heatSome),
            const SizedBox(width: AriseSpacing.sm),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
