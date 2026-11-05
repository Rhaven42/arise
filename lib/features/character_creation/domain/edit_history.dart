import 'package:arise/core/config/game_config.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Historique d'édition avec annuler / rétablir (20 actions par défaut).
@immutable
class EditHistory<T> {
  const EditHistory._(this._past, this.current, this._future, this.capacity);

  factory EditHistory.start(T value, {int? capacity}) => EditHistory._(
    const [],
    value,
    const [],
    capacity ?? gameConfig.character.undoHistorySize,
  );

  final List<T> _past;
  final T current;
  final List<T> _future;
  final int capacity;

  bool get canUndo => _past.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;

  /// Nouvelle valeur : elle efface les actions annulées ; seules les
  /// [capacity] dernières actions restent annulables.
  EditHistory<T> push(T value) {
    if (value == current) return this;
    final past = [..._past, current];
    final trimmed = past.length > capacity
        ? past.sublist(past.length - capacity)
        : past;
    return EditHistory._(trimmed, value, const [], capacity);
  }

  /// Remplace la valeur courante sans créer d'action annulable.
  EditHistory<T> replace(T value) =>
      EditHistory._(_past, value, _future, capacity);

  EditHistory<T> undo() {
    if (!canUndo) return this;
    return EditHistory._(
      _past.sublist(0, _past.length - 1),
      _past.last,
      [current, ..._future],
      capacity,
    );
  }

  EditHistory<T> redo() {
    if (!canRedo) return this;
    return EditHistory._(
      [..._past, current],
      _future.first,
      _future.sublist(1),
      capacity,
    );
  }
}
