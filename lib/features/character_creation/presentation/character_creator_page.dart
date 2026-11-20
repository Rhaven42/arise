import 'dart:convert';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/domain/character_scene.dart';
import 'package:arise/features/avatar/presentation/character_renderer.dart';
import 'package:arise/features/character_creation/domain/character_palette.dart';
import 'package:arise/features/character_creation/domain/character_rules.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
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
enum CreatorTab { body, hair, sheet }

/// Créateur de personnage : rendu en direct, réglages répartis en onglets
/// (race et peau, coiffure et barbe, nom et fiche) et scène réglable.
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
                    focus: _tabs.index == CreatorTab.hair.index
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
                    Tab(text: l10n.characterTabHair),
                    Tab(text: l10n.characterTabSheet),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _BodyTab(sheet: value.sheet),
                      _HairTab(
                        sheet: value.sheet,
                        worn: value.saved?.hairStyle,
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

/// Rendu du personnage avec les réglages de scène (éclairage, avant / après).
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
    return ListView(
      key: CharacterCreatorPage.tabKey(CreatorTab.body),
      padding: const EdgeInsets.all(AriseSpacing.md),
      children: [
        _ChoiceDropdown<CharacterSex>(
          label: l10n.characterSex,
          values: CharacterSex.values,
          value: sheet.sex,
          nameOf: (sex) => l10n.characterSexName(sex.name),
          onChanged: controller.setSex,
        ),
        const SizedBox(height: AriseSpacing.md),
        Text(l10n.characterRace, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AriseSpacing.xs),
        Wrap(
          spacing: AriseSpacing.xs,
          runSpacing: AriseSpacing.xs,
          children: [
            for (final race in CharacterRace.values)
              ChoiceChip(
                label: Text(raceLabel(l10n, race, sheet.sex)),
                selected: race == sheet.race,
                onSelected: (_) => controller.setRace(race),
              ),
          ],
        ),
        const SizedBox(height: AriseSpacing.md),
        _SwatchChips(
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

class _HairTab extends ConsumerWidget {
  const _HairTab({required this.sheet, this.worn});

  final CharacterSheet sheet;

  /// Coiffure du personnage enregistré (toujours utilisable).
  final int? worn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(characterCreatorControllerProvider.notifier);
    final inventory = ref.watch(inventoryProvider).value ?? const Inventory();
    bool locked(int style) =>
        style > 0 &&
        !hairStyleAvailable(inventory, style, worn: worn ?? sheet.hairStyle);
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

    final male = sheet.sex == CharacterSex.male;
    return ListView(
      key: CharacterCreatorPage.tabKey(CreatorTab.hair),
      padding: const EdgeInsets.all(AriseSpacing.md),
      children: [
        Text(
          l10n.characterHairStyle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AriseSpacing.xs),
        Wrap(
          spacing: AriseSpacing.xs,
          runSpacing: AriseSpacing.xs,
          children: [
            for (final style in hairStylesFor(sheet.race, sheet.sex))
              ChoiceChip(
                avatar: locked(style)
                    ? const Icon(Icons.lock_outline, size: 18)
                    : null,
                label: Text(hairStyleLabel(l10n, sheet.sex, style)),
                selected: style == sheet.hairStyle,
                onSelected: (_) => locked(style)
                    ? showLocked()
                    : controller.edit((s) => s.copyWith(hairStyle: style)),
              ),
          ],
        ),
        const SizedBox(height: AriseSpacing.md),
        _SwatchChips(
          label: l10n.characterHairColor,
          swatches: hairColors,
          value: sheet.hairColor,
          nameOf: (s) => l10n.characterHairColorName(s.id),
          onChanged: (c) => controller.edit((s) => s.copyWith(hairColor: c)),
        ),
        if (male) ...[
          const SizedBox(height: AriseSpacing.md),
          Text(
            l10n.characterBeard,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AriseSpacing.xs),
          Wrap(
            spacing: AriseSpacing.xs,
            runSpacing: AriseSpacing.xs,
            children: [
              for (var style = 0; style <= beardStyleCount; style++)
                ChoiceChip(
                  label: Text(beardLabel(l10n, style)),
                  selected: style == sheet.beardStyle,
                  onSelected: (_) =>
                      controller.edit((s) => s.copyWith(beardStyle: style)),
                ),
            ],
          ),
          if (sheet.beardStyle > 0) ...[
            const SizedBox(height: AriseSpacing.md),
            _SwatchChips(
              label: l10n.characterBeardColor,
              swatches: hairColors,
              value: sheet.beardColor ?? sheet.hairColor,
              nameOf: (s) => l10n.characterHairColorName(s.id),
              onChanged: (c) =>
                  controller.edit((s) => s.copyWith(beardColor: c)),
            ),
          ],
        ],
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

/// Pastilles de couleur (nom lu par le lecteur d'écran, coche sur la
/// couleur choisie : la couleur n'est pas le seul repère).
class _SwatchChips extends StatelessWidget {
  const _SwatchChips({
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
    final l10n = AppLocalizations.of(context);
    final selected = swatchOf(swatches, value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selected == null
              ? label
              : l10n.characterSwatchValue(label, nameOf(selected)),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AriseSpacing.xs),
        Wrap(
          spacing: AriseSpacing.xs,
          runSpacing: AriseSpacing.xs,
          children: [
            for (final swatch in swatches)
              Semantics(
                button: true,
                selected: swatch == selected,
                child: Tooltip(
                  message: nameOf(swatch),
                  child: InkWell(
                    onTap: () => onChanged(swatch.color),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(swatch.color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: swatch == selected
                              ? AriseColors.goldBright
                              : AriseColors.parchmentMuted,
                          width: swatch == selected ? 3 : 1,
                        ),
                      ),
                      child: swatch == selected
                          ? Icon(
                              Icons.check,
                              color:
                                  Color(swatch.color).computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
