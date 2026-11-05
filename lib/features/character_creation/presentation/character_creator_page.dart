import 'dart:convert';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/presentation/character_renderer.dart';
import 'package:arise/features/character_creation/domain/character_palette.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:arise/features/character_creation/presentation/character_labels.dart';
import 'package:arise/features/character_creation/presentation/character_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Créateur de personnage : menus déroulants, curseurs, nom, fiche JSON et
/// rendu 3D en direct.
class CharacterCreatorPage extends ConsumerStatefulWidget {
  const CharacterCreatorPage({super.key});

  /// Liste des réglages (repère pour les tests et les captures).
  static const formKey = Key('character-form');

  @override
  ConsumerState<CharacterCreatorPage> createState() =>
      _CharacterCreatorPageState();
}

class _CharacterCreatorPageState extends ConsumerState<CharacterCreatorPage> {
  final _name = TextEditingController();
  bool _nameLoaded = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    final ok = await ref
        .read(characterCreatorControllerProvider.notifier)
        .confirm();
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.characterSaved)));
    context.go(AppRoutes.systemHome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final creator = ref.watch(characterCreatorControllerProvider);
    final controller = ref.read(characterCreatorControllerProvider.notifier);
    final value = creator.value;
    if (value != null && !_nameLoaded) {
      _nameLoaded = true;
      _name.text = value.sheet.name;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.characterTitle),
        actions: [
          IconButton(
            tooltip: l10n.characterUndo,
            icon: const Icon(Icons.undo),
            onPressed: (value?.history.canUndo ?? false)
                ? controller.undo
                : null,
          ),
          IconButton(
            tooltip: l10n.characterRedo,
            icon: const Icon(Icons.redo),
            onPressed: (value?.history.canRedo ?? false)
                ? controller.redo
                : null,
          ),
        ],
      ),
      body: value == null
          ? const Center(child: CircularProgressIndicator())
          : _CreatorBody(
              state: value,
              nameController: _name,
              onConfirm: _confirm,
            ),
    );
  }
}

class _CreatorBody extends ConsumerWidget {
  const _CreatorBody({
    required this.state,
    required this.nameController,
    required this.onConfirm,
  });

  final CreatorState state;
  final TextEditingController nameController;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sheet = state.sheet;
    final controller = ref.read(characterCreatorControllerProvider.notifier);
    final renderer = ref.watch(characterRendererProvider);
    final config = gameConfig.character;
    final height = MediaQuery.sizeOf(context).height;

    return Column(
      children: [
        Semantics(
          label: l10n.characterPreviewSemantics(describeCharacter(l10n, sheet)),
          child: SizedBox(
            height: height * 0.4,
            child: renderer.build(appearance: CharacterAppearance.of(sheet)),
          ),
        ),
        Expanded(
          child: ListView(
            key: CharacterCreatorPage.formKey,
            padding: const EdgeInsets.all(AriseSpacing.md),
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<CharacterSex>(
                      key: ValueKey('sex-${sheet.sex}'),
                      initialValue: sheet.sex,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l10n.characterSex),
                      items: [
                        for (final sex in CharacterSex.values)
                          DropdownMenuItem(
                            value: sex,
                            child: Text(l10n.characterSexName(sex.name)),
                          ),
                      ],
                      onChanged: (v) => v == null ? null : controller.setSex(v),
                    ),
                  ),
                  const SizedBox(width: AriseSpacing.md),
                  Expanded(
                    child: DropdownButtonFormField<CharacterRace>(
                      key: ValueKey('race-${sheet.race}-${sheet.sex}'),
                      initialValue: sheet.race,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.characterRace,
                      ),
                      items: [
                        for (final race in CharacterRace.values)
                          DropdownMenuItem(
                            value: race,
                            child: Text(raceLabel(l10n, race, sheet.sex)),
                          ),
                      ],
                      onChanged: (v) =>
                          v == null ? null : controller.setRace(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AriseSpacing.md),
              _LabeledSlider(
                label: l10n.characterSliderValue(
                  l10n.characterCorpulence,
                  corpulenceLabel(l10n, sheet),
                ),
                value: sheet.corpulence,
                divisions: 20,
                onStart: controller.beginGesture,
                onChanged: (v) =>
                    controller.preview((s) => s.copyWith(corpulence: v)),
                onEnd: controller.endGesture,
              ),
              _LabeledSlider(
                label: l10n.characterSliderValue(
                  l10n.characterMusculature,
                  musculatureLabel(l10n, sheet),
                ),
                value: sheet.musculature,
                divisions: 20,
                onStart: controller.beginGesture,
                onChanged: (v) =>
                    controller.preview((s) => s.copyWith(musculature: v)),
                onEnd: controller.endGesture,
              ),
              _LabeledSlider(
                label: l10n.characterHeight(sheet.heightCm),
                value: sheet.heightCm.toDouble(),
                min: config.heightMinCm.toDouble(),
                max: config.heightMaxCm.toDouble(),
                divisions: config.heightMaxCm - config.heightMinCm,
                onStart: controller.beginGesture,
                onChanged: (v) =>
                    controller.preview((s) => s.copyWith(heightCm: v.round())),
                onEnd: controller.endGesture,
              ),
              const SizedBox(height: AriseSpacing.sm),
              _SwatchDropdown(
                label: l10n.characterSkin,
                swatches: skinsFor(sheet.race),
                value: sheet.skinColor,
                nameOf: (s) => l10n.characterSkinName(s.id),
                onChanged: (c) =>
                    controller.edit((s) => s.copyWith(skinColor: c)),
              ),
              const SizedBox(height: AriseSpacing.md),
              DropdownButtonFormField<int>(
                key: ValueKey('hair-${sheet.hairStyle}'),
                initialValue: sheet.hairStyle,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.characterHairStyle),
                items: [
                  for (var i = 1; i <= hairStyleCount; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(hairStyleLabel(l10n, i)),
                    ),
                ],
                onChanged: (v) => v == null
                    ? null
                    : controller.edit((s) => s.copyWith(hairStyle: v)),
              ),
              const SizedBox(height: AriseSpacing.md),
              _SwatchDropdown(
                label: l10n.characterHairColor,
                swatches: hairColors,
                value: sheet.hairColor,
                nameOf: (s) => l10n.characterHairColorName(s.id),
                onChanged: (c) =>
                    controller.edit((s) => s.copyWith(hairColor: c)),
              ),
              const SizedBox(height: AriseSpacing.md),
              TextField(
                controller: nameController,
                maxLength: config.usernameMaxLength,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.characterName,
                  helperText: l10n.characterNameHint(
                    config.usernameMinLength,
                    config.usernameMaxLength,
                  ),
                  errorText: nameIssueLabel(l10n, state.nameIssue),
                ),
                onChanged: controller.setName,
              ),
              const SizedBox(height: AriseSpacing.sm),
              Wrap(
                spacing: AriseSpacing.sm,
                runSpacing: AriseSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: controller.randomize,
                    icon: const Icon(Icons.casino_outlined),
                    label: Text(l10n.characterRandom),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.reset,
                    icon: const Icon(Icons.restart_alt),
                    label: Text(l10n.characterReset),
                  ),
                ],
              ),
              const SizedBox(height: AriseSpacing.sm),
              ExpansionTile(
                title: Text(l10n.characterSheetJson),
                tilePadding: EdgeInsets.zero,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AriseSpacing.sm),
                    color: AriseColors.stoneDark,
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ')
                          .convert(sheet.toJson()),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AriseSpacing.md),
              AriseButton(
                label: l10n.characterConfirm,
                icon: Icons.check,
                onPressed: onConfirm,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.divisions,
    required this.onStart,
    required this.onChanged,
    required this.onEnd,
    this.min = 0,
    this.max = 1,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final VoidCallback onStart;
  final ValueChanged<double> onChanged;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          semanticFormatterCallback: (_) => label,
          onChangeStart: (_) => onStart(),
          onChanged: onChanged,
          onChangeEnd: (_) => onEnd(),
        ),
      ],
    );
  }
}

class _SwatchDropdown extends StatelessWidget {
  const _SwatchDropdown({
    required this.label,
    required this.swatches,
    required this.value,
    required this.nameOf,
    required this.onChanged,
  });

  final String label;
  final List<Swatch> swatches;
  final int value;
  final String Function(Swatch swatch) nameOf;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = swatchOf(swatches, value) ?? swatches.first;
    return DropdownButtonFormField<int>(
      key: ValueKey('$label-${selected.color}'),
      initialValue: selected.color,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final swatch in swatches)
          DropdownMenuItem(
            value: swatch.color,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Color(swatch.color),
                    shape: BoxShape.circle,
                    border: Border.all(color: AriseColors.parchmentMuted),
                  ),
                ),
                const SizedBox(width: AriseSpacing.sm),
                Expanded(child: Text(nameOf(swatch))),
              ],
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
