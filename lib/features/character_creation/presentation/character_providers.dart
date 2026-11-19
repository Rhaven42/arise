import 'dart:async';
import 'dart:math';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/character_creation/data/drift_character_repository.dart';
import 'package:arise/features/character_creation/domain/character_repository.dart';
import 'package:arise/features/character_creation/domain/character_rules.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:arise/features/character_creation/domain/edit_history.dart';
import 'package:arise/features/character_creation/domain/name_rules.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:arise/features/inventory/presentation/inventory_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'character_providers.g.dart';

@Riverpod(keepAlive: true)
CharacterRepository characterRepository(Ref ref) => DriftCharacterRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(clockProvider),
);

/// Personnage validé (ou `null` tant qu'il n'a pas été créé).
@riverpod
Stream<CharacterSheet?> savedCharacter(Ref ref) =>
    ref.watch(characterRepositoryProvider).watch();

/// Tirage du bouton « Aléatoire » (remplacé dans les tests).
@Riverpod(keepAlive: true)
Random characterRandom(Ref ref) => Random();

/// État du créateur : historique d'édition et dernier contrôle du nom.
class CreatorState {
  const CreatorState({
    required this.history,
    required this.origin,
    this.nameIssue,
    this.saved,
  });

  final EditHistory<CharacterSheet> history;
  final NameIssue? nameIssue;

  /// Fiche déjà validée, pour savoir si les choix ont changé.
  final CharacterSheet? saved;

  CharacterSheet get sheet => history.current;

  /// Fiche d'ouverture du créateur, pour la comparaison avant / après.
  final CharacterSheet origin;

  CreatorState copyWith({
    EditHistory<CharacterSheet>? history,
    NameIssue? nameIssue,
    bool clearIssue = false,
    CharacterSheet? saved,
  }) => CreatorState(
    history: history ?? this.history,
    origin: origin,
    nameIssue: clearIssue ? null : nameIssue ?? this.nameIssue,
    saved: saved ?? this.saved,
  );
}

/// Créateur de personnage : chaque choix est conservé en brouillon.
@riverpod
class CharacterCreatorController extends _$CharacterCreatorController {
  @override
  Future<CreatorState> build() async {
    final repository = ref.watch(characterRepositoryProvider);
    final saved = await repository.read();
    final draft = await repository.readDraft();
    final start = draft ?? saved ?? defaultSheet();
    return CreatorState(
      history: EditHistory.start(start),
      origin: saved ?? start,
      saved: saved,
    );
  }

  CreatorState? get _state => state.value;

  void _set(EditHistory<CharacterSheet> history) {
    final current = _state;
    if (current == null) return;
    state = AsyncData(current.copyWith(history: history, clearIssue: true));
    unawaited(ref.read(characterRepositoryProvider).saveDraft(history.current));
  }

  /// Applique un choix (annulable).
  void edit(CharacterSheet Function(CharacterSheet sheet) change) {
    final current = _state;
    if (current == null) return;
    _set(current.history.push(sanitizeSheet(change(current.sheet))));
  }

  void setSex(CharacterSex sex) => edit((s) => changeSex(s, sex));

  void setRace(CharacterRace race) => edit((s) => changeRace(s, race));

  /// Le nom se tape lettre par lettre : il n'entre pas dans l'historique.
  void setName(String name) {
    final current = _state;
    if (current == null) return;
    _set(current.history.replace(current.sheet.copyWith(name: name)));
  }

  void undo() {
    final current = _state;
    if (current != null && current.history.canUndo) {
      _set(_keepName(current.history.undo(), current.sheet.name));
    }
  }

  void redo() {
    final current = _state;
    if (current != null && current.history.canRedo) {
      _set(_keepName(current.history.redo(), current.sheet.name));
    }
  }

  /// Annuler un choix ne touche pas au nom en cours de saisie.
  static EditHistory<CharacterSheet> _keepName(
    EditHistory<CharacterSheet> history,
    String name,
  ) => history.replace(history.current.copyWith(name: name));

  /// Tirage au hasard parmi les coiffures utilisables (les coiffures de la
  /// boutique doivent avoir été achetées).
  void randomize() {
    final inventory = ref.read(inventoryProvider).value ?? const Inventory();
    final worn = _state?.saved?.hairStyle;
    edit(
      (s) => randomSheet(
        ref.read(characterRandomProvider),
        name: s.name,
        hairStyles: availableHairStyles(
          inventory,
          count: hairStyleCount,
          worn: worn,
        ),
      ),
    );
  }

  void reset() => edit((s) => defaultSheet(sex: s.sex).copyWith(name: s.name));

  /// Valide le personnage ; renvoie `false` si le nom est refusé.
  Future<bool> confirm() async {
    final current = _state;
    if (current == null) return false;
    final sheet = current.sheet.copyWith(name: current.sheet.name.trim());
    final issue = checkName(sheet.name);
    if (issue != null) {
      state = AsyncData(current.copyWith(nameIssue: issue));
      return false;
    }
    final repository = ref.read(characterRepositoryProvider);
    await repository.save(sheet);
    await repository.clearDraft();
    if (ref.mounted) {
      state = AsyncData(current.copyWith(saved: sheet, clearIssue: true));
    }
    return true;
  }
}
