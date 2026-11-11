import 'dart:convert';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/domain/character_scene.dart';
import 'package:arise/features/avatar/presentation/character_renderer.dart';
import 'package:arise/features/character_creation/domain/body_presets.dart';
import 'package:arise/features/character_creation/domain/character_palette.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:arise/features/character_creation/domain/hair_styles.dart';
import 'package:arise/features/character_creation/presentation/character_labels.dart';
import 'package:arise/features/character_creation/presentation/character_providers.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:arise/features/inventory/presentation/inventory_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Onglets du créateur.
enum CreatorTab { body, face, hair, sheet }

/// Créateur de personnage : rendu 3D en direct, réglages répartis en
/// onglets (corps, visage, coiffure, nom et fiche) et scène réglable.
class CharacterCreatorPage extends ConsumerStatefulWidget {
  const CharacterCreatorPage({super.key});

  /// Liste défilante d'un onglet (repère pour les tests et les captures).
  static Key tabKey(CreatorTab tab) => ValueKey('character-tab-${tab.name}');

  @override
  ConsumerState<CharacterCreatorPage> createState() =>
      _CharacterCreatorPageState();
}

class _CharacterCreatorPageState extends ConsumerState<CharacterCreatorPage>
    with SingleTickerProviderStateMixin {
  final _name = TextEditingController();
  final _snapshots = CharacterSnapshotController();
  late final TabController _tabs;
  bool _nameLoaded = false;
  SceneLighting _lighting = SceneLighting.tavern;
  bool _showBefore = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: CreatorTab.values.length, vsync: this)
      ..addListener(_onTab);
  }

  void _onTab() {
    if (!_tabs.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTab)
      ..dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    final ok = await ref
        .read(characterCreatorControllerProvider.notifier)
        .confirm();
    if (!mounted) return;
    if (!ok) {
      // Le nom est refusé : on montre le champ et son message.
      _tabs.animateTo(CreatorTab.sheet.index);
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.characterSaved)));
    context.go(AppRoutes.systemHome);
  }

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final png = await _snapshots.capture();
    if (png == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.characterShareFailed)),
      );
      return;
    }
    await ref
        .read(snapshotSharerProvider)
        .sharePng(png, fileName: l10n.characterSnapshotFileName);
  }

  void _toggleFavorite(int style) {
    final l10n = AppLocalizations.of(context);
    final result = ref
        .read(characterCreatorControllerProvider.notifier)
        .toggleFavorite(style);
    if (result == FavoriteToggle.full) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.characterFavoritesFull(
              gameConfig.character.favoriteHairstylesMax,
            ),
          ),
        ),
      );
    }
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
          IconButton(
            tooltip: l10n.characterShare,
            icon: const Icon(Icons.share_outlined),
            onPressed: value == null ? null : _share,
          ),
        ],
      ),
      body: value == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _Preview(
                  state: value,
                  scene: CharacterScene(
                    lighting: _lighting,
                    focus: _tabs.index == CreatorTab.face.index
                        ? SceneFocus.face
                        : SceneFocus.body,
                  ),
                  snapshots: _snapshots,
                  showBefore: _showBefore,
                  onLighting: (l) => setState(() => _lighting = l),
                  onBeforeAfter: () =>
                      setState(() => _showBefore = !_showBefore),
                ),
                TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: l10n.characterTabBody),
                    Tab(text: l10n.characterTabFace),
                    Tab(text: l10n.characterTabHair),
                    Tab(text: l10n.characterTabSheet),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _BodyTab(sheet: value.sheet),
                      _FaceTab(sheet: value.sheet),
                      _HairTab(
                        sheet: value.sheet,
                        worn: value.saved?.hairStyle,
                        onToggleFavorite: _toggleFavorite,
                      ),
                      _SheetTab(state: value, nameController: _name),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AriseSpacing.sm),
                    child: AriseButton(
                      label: l10n.characterConfirm,
                      icon: Icons.check,
                      onPressed: _confirm,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Rendu 3D avec les réglages de scène (éclairage, avant / après).
class _Preview extends ConsumerWidget {
  const _Preview({
    required this.state,
    required this.scene,
    required this.snapshots,
    required this.showBefore,
    required this.onLighting,
    required this.onBeforeAfter,
  });

  final CreatorState state;
  final CharacterScene scene;
  final CharacterSnapshotController snapshots;
  final bool showBefore;
  final ValueChanged<SceneLighting> onLighting;
  final VoidCallback onBeforeAfter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final renderer = ref.watch(characterRendererProvider);
    final shown = showBefore ? state.origin : state.sheet;
    final height = MediaQuery.sizeOf(context).height;
    return SizedBox(
      height: height * 0.36,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            label: l10n.characterPreviewSemantics(
              describeCharacter(l10n, shown),
            ),
            child: renderer.build(
              appearance: CharacterAppearance.of(shown),
              scene: scene,
              snapshots: snapshots,
            ),
          ),
          if (showBefore)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.all(AriseSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AriseSpacing.sm,
                  vertical: AriseSpacing.xs,
                ),
                color: AriseColors.stoneDark,
                child: Text(l10n.characterShowingBefore),
              ),
            ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(AriseSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<SceneLighting>(
                    tooltip: l10n.characterLighting,
                    icon: const Icon(Icons.wb_twilight),
                    initialValue: scene.lighting,
                    onSelected: onLighting,
                    itemBuilder: (_) => [
                      for (final l in SceneLighting.values)
                        PopupMenuItem(
                          value: l,
                          child: Text(l10n.characterLightingName(l.name)),
                        ),
                    ],
                  ),
                  IconButton(
                    tooltip: l10n.characterBeforeAfter,
                    isSelected: showBefore,
                    icon: const Icon(Icons.compare),
                    onPressed: onBeforeAfter,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyTab extends ConsumerWidget {
  const _BodyTab({required this.sheet});

  final CharacterSheet sheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(characterCreatorControllerProvider.notifier);
    final config = gameConfig.character;
    final selectedPreset = presetOf(sheet);
    return ListView(
      key: CharacterCreatorPage.tabKey(CreatorTab.body),
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
                decoration: InputDecoration(labelText: l10n.characterRace),
                items: [
                  for (final race in CharacterRace.values)
                    DropdownMenuItem(
                      value: race,
                      child: Text(raceLabel(l10n, race, sheet.sex)),
                    ),
                ],
                onChanged: (v) => v == null ? null : controller.setRace(v),
              ),
            ),
          ],
        ),
        const SizedBox(height: AriseSpacing.md),
        Text(
          l10n.characterPresets,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(
          l10n.characterPresetsHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AriseSpacing.xs),
        Wrap(
          spacing: AriseSpacing.xs,
          runSpacing: AriseSpacing.xs,
          children: [
            for (final preset in presetsFor(sheet.sex))
              ChoiceChip(
                label: Text(presetLabel(l10n, sheet.sex, preset.id)),
                selected: preset == selectedPreset,
                onSelected: (_) => controller.applyBodyPreset(preset),
              ),
          ],
        ),
        const SizedBox(height: AriseSpacing.md),
        _SheetSlider(
          label: l10n.characterSliderValue(
            l10n.characterCorpulence,
            corpulenceLabel(l10n, sheet),
          ),
          value: sheet.corpulence,
          change: (s, v) => s.copyWith(corpulence: v),
        ),
        _SheetSlider(
          label: l10n.characterSliderValue(
            l10n.characterMusculature,
            musculatureLabel(l10n, sheet),
          ),
          value: sheet.musculature,
          change: (s, v) => s.copyWith(musculature: v),
        ),
        _SheetSlider(
          label: l10n.characterHeight(sheet.heightCm),
          value: sheet.heightCm.toDouble(),
          min: config.heightMinCm.toDouble(),
          max: config.heightMaxCm.toDouble(),
          divisions: config.heightMaxCm - config.heightMinCm,
          change: (s, v) => s.copyWith(heightCm: v.round()),
        ),
        const SizedBox(height: AriseSpacing.sm),
        _SwatchDropdown(
          label: l10n.characterSkin,
          swatches: skinsFor(sheet.race),
          value: sheet.skinColor,
          nameOf: (s) => l10n.characterSkinName(s.id),
          onChanged: (c) => controller.edit((s) => s.copyWith(skinColor: c)),
        ),
      ],
    );
  }
}

class _FaceTab extends ConsumerWidget {
  const _FaceTab({required this.sheet});

  final CharacterSheet sheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(characterCreatorControllerProvider.notifier);
    String label(String name, double v) =>
        l10n.characterSliderValue(name, faceStepLabel(l10n, v));
    final isMale = sheet.sex == CharacterSex.male;
    return ListView(
      key: CharacterCreatorPage.tabKey(CreatorTab.face),
      padding: const EdgeInsets.all(AriseSpacing.md),
      children: [
        _SheetSlider(
          label: label(l10n.characterFaceJaw, sheet.faceJaw),
          value: sheet.faceJaw,
          change: (s, v) => s.copyWith(faceJaw: v),
        ),
        _SheetSlider(
          label: label(l10n.characterFaceNose, sheet.faceNose),
          value: sheet.faceNose,
          change: (s, v) => s.copyWith(faceNose: v),
        ),
        _SheetSlider(
          label: label(l10n.characterFaceMouth, sheet.faceMouth),
          value: sheet.faceMouth,
          change: (s, v) => s.copyWith(faceMouth: v),
        ),
        _SheetSlider(
          label: label(l10n.characterFaceCheeks, sheet.faceCheeks),
          value: sheet.faceCheeks,
          change: (s, v) => s.copyWith(faceCheeks: v),
        ),
        _SheetSlider(
          label: label(l10n.characterFaceEars, sheet.faceEars),
          value: sheet.faceEars,
          change: (s, v) => s.copyWith(faceEars: v),
        ),
        const SizedBox(height: AriseSpacing.sm),
        _SwatchDropdown(
          label: l10n.characterEyeColor,
          swatches: eyeColors,
          value: sheet.eyeColor,
          nameOf: (s) => l10n.characterEyeColorName(s.id),
          onChanged: (c) => controller.edit((s) => s.copyWith(eyeColor: c)),
        ),
        const SizedBox(height: AriseSpacing.md),
        _ChoiceDropdown<int>(
          label: l10n.characterEyebrows,
          values: [for (var i = 1; i <= eyebrowStyleCount; i++) i],
          value: sheet.eyebrowStyle,
          nameOf: (i) => eyebrowLabel(l10n, i),
          onChanged: (i) => controller.edit((s) => s.copyWith(eyebrowStyle: i)),
        ),
        if (isMale) ...[
          const SizedBox(height: AriseSpacing.md),
          _ChoiceDropdown<int>(
            label: l10n.characterBeard,
            values: [for (var i = 0; i <= beardStyleCount; i++) i],
            value: sheet.beardStyle,
            nameOf: (i) => beardLabel(l10n, i),
            onChanged: (i) => controller.edit((s) => s.copyWith(beardStyle: i)),
          ),
          if (sheet.beardStyle > 0) ...[
            const SizedBox(height: AriseSpacing.md),
            _SwatchDropdown(
              label: l10n.characterBeardColor,
              swatches: [
                Swatch('same', sheet.hairColor),
                for (final s in hairColors)
                  if (s.color != sheet.hairColor) s,
              ],
              value: sheet.beardColor ?? sheet.hairColor,
              nameOf: (s) => s.id == 'same'
                  ? l10n.characterBeardColorSame
                  : l10n.characterHairColorName(s.id),
              onChanged: (c) => controller.edit(
                (s) => s.copyWith(beardColor: c == s.hairColor ? null : c),
              ),
            ),
          ],
        ],
        const SizedBox(height: AriseSpacing.md),
        _ChoiceDropdown<int>(
          label: l10n.characterMakeup,
          values: [for (var i = 0; i <= makeupStyleCount; i++) i],
          value: sheet.makeupStyle,
          nameOf: (i) => makeupLabel(l10n, i),
          onChanged: (i) => controller.edit((s) => s.copyWith(makeupStyle: i)),
        ),
      ],
    );
  }
}

/// Filtre de la liste des coiffures.
enum _HairFilter { favorites, short, tied, long }

class _HairTab extends ConsumerStatefulWidget {
  const _HairTab({
    required this.sheet,
    required this.onToggleFavorite,
    this.worn,
  });

  final CharacterSheet sheet;
  final ValueChanged<int> onToggleFavorite;

  /// Coiffure du personnage enregistré (toujours utilisable).
  final int? worn;

  @override
  ConsumerState<_HairTab> createState() => _HairTabState();
}

class _HairTabState extends ConsumerState<_HairTab> {
  _HairFilter? _filter;

  /// Filtre par défaut : la famille de la coiffure portée.
  _HairFilter get _current =>
      _filter ??
      switch (hairStyleCategory[widget.sheet.hairStyle]) {
        HairCategory.tied => _HairFilter.tied,
        HairCategory.long => _HairFilter.long,
        _ => _HairFilter.short,
      };

  List<int> _styles(_HairFilter filter) => switch (filter) {
    _HairFilter.favorites => widget.sheet.favoriteHairStyles,
    _HairFilter.short => hairStylesIn(HairCategory.short),
    _HairFilter.tied => hairStylesIn(HairCategory.tied),
    _HairFilter.long => hairStylesIn(HairCategory.long),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(characterCreatorControllerProvider.notifier);
    final sheet = widget.sheet;
    final filter = _current;
    final styles = _styles(filter);
    final inventory = ref.watch(inventoryProvider).value ?? const Inventory();
    bool locked(int style) => !hairStyleAvailable(
      inventory,
      style,
      worn: widget.worn ?? sheet.hairStyle,
    );
    void showLocked() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.characterHairLocked),
          action: SnackBarAction(
            label: l10n.characterGoToShop,
            onPressed: () => context.go(AppRoutes.shop),
          ),
        ),
      );
    }

    return ListView(
      key: CharacterCreatorPage.tabKey(CreatorTab.hair),
      padding: const EdgeInsets.all(AriseSpacing.md),
      children: [
        Text(
          l10n.characterHairCategory,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AriseSpacing.xs),
        Wrap(
          spacing: AriseSpacing.xs,
          runSpacing: AriseSpacing.xs,
          children: [
            for (final f in _HairFilter.values)
              ChoiceChip(
                avatar: f == _HairFilter.favorites
                    ? const Icon(Icons.star, size: 18)
                    : null,
                label: Text(l10n.characterHairCategoryName(f.name)),
                selected: f == filter,
                onSelected: (_) => setState(() => _filter = f),
              ),
          ],
        ),
        const SizedBox(height: AriseSpacing.sm),
        if (styles.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AriseSpacing.md),
            child: Text(l10n.characterHairFavoritesEmpty),
          ),
        for (final style in styles)
          ListTile(
            contentPadding: EdgeInsets.zero,
            selected: style == sheet.hairStyle,
            leading: Icon(
              locked(style)
                  ? Icons.lock_outline
                  : style == sheet.hairStyle
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: Text(hairStyleLabel(l10n, style)),
            subtitle: locked(style) ? Text(l10n.characterHairLocked) : null,
            onTap: locked(style)
                ? showLocked
                : () => controller.edit((s) => s.copyWith(hairStyle: style)),
            trailing: IconButton(
              tooltip: sheet.favoriteHairStyles.contains(style)
                  ? l10n.characterFavoriteRemove
                  : l10n.characterFavoriteAdd,
              icon: Icon(
                sheet.favoriteHairStyles.contains(style)
                    ? Icons.star
                    : Icons.star_border,
              ),
              onPressed: () => widget.onToggleFavorite(style),
            ),
          ),
        const SizedBox(height: AriseSpacing.md),
        _SwatchDropdown(
          label: l10n.characterHairColor,
          swatches: hairColors,
          value: sheet.hairColor,
          nameOf: (s) => l10n.characterHairColorName(s.id),
          onChanged: (c) => controller.edit((s) => s.copyWith(hairColor: c)),
        ),
      ],
    );
  }
}

class _SheetTab extends ConsumerWidget {
  const _SheetTab({required this.state, required this.nameController});

  final CreatorState state;
  final TextEditingController nameController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(characterCreatorControllerProvider.notifier);
    final config = gameConfig.character;
    return ListView(
      key: CharacterCreatorPage.tabKey(CreatorTab.sheet),
      padding: const EdgeInsets.all(AriseSpacing.md),
      children: [
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
                    .convert(state.sheet.toJson()),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Curseur relié à la fiche : un glissement complet = une seule action
/// annulable.
class _SheetSlider extends ConsumerWidget {
  const _SheetSlider({
    required this.label,
    required this.value,
    required this.change,
    this.min = 0,
    this.max = 1,
    this.divisions = 20,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final CharacterSheet Function(CharacterSheet sheet, double value) change;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(characterCreatorControllerProvider.notifier);
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
          onChangeStart: (_) => controller.beginGesture(),
          onChanged: (v) => controller.preview((s) => change(s, v)),
          onChangeEnd: (_) => controller.endGesture(),
        ),
      ],
    );
  }
}

/// Menu déroulant d'une liste de choix.
class _ChoiceDropdown<T> extends StatelessWidget {
  const _ChoiceDropdown({
    required this.label,
    required this.values,
    required this.value,
    required this.nameOf,
    required this.onChanged,
  });

  final String label;
  final List<T> values;
  final T value;
  final String Function(T value) nameOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final v in values)
          DropdownMenuItem(value: v, child: Text(nameOf(v))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
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
