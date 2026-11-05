import 'package:arise/features/workout_player/domain/workout_run.dart';
import 'package:arise/features/workout_player/domain/workout_step.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime.utc(2026, 11, 5, 18);
DateTime _at(int seconds) => _t0.add(Duration(seconds: seconds));

const _set = WorkoutStep(
  kind: StepKind.work,
  exerciseId: 'push_up',
  targetReps: 10,
  setNumber: 1,
  setCount: 1,
  asksIntensity: true,
);
const _rest = WorkoutStep(kind: StepKind.rest, targetSeconds: 30);
const _round = WorkoutStep(
  kind: StepKind.work,
  exerciseId: 'burpee',
  targetSeconds: 20,
);

void main() {
  test('une séance sans étape est terminée dès le départ', () {
    expect(WorkoutRun.start(const [], _t0).isFinished, isTrue);
  });

  test('une série terminée demande l’intensité puis passe au repos', () {
    var run = WorkoutRun.start(const [_set, _rest, _round], _t0);
    run = run.completeWork(_at(25), reps: 8);
    expect(run.isAwaitingIntensity, isTrue);
    expect(run.index, 0);

    run = run.submitIntensity(_at(30), 7);
    expect(run.index, 1);
    expect(run.results.single.reps, 8);
    expect(run.results.single.rpe, 7);
    expect(run.results.single.activeSeconds, 25);
    expect(run.remaining(_at(40)), const Duration(seconds: 20));
  });

  test('les comptes à rebours avancent seuls, même si l’horloge tarde', () {
    var run = WorkoutRun.start(const [_rest, _round, _rest], _t0);
    // 55 s plus tard : repos (30 s) et round (20 s) terminés, 5 s du repos
    // suivant écoulées.
    run = run.tick(_at(55));
    expect(run.index, 2);
    expect(run.results.single.activeSeconds, 20);
    expect(run.remaining(_at(55)), const Duration(seconds: 25));
    run = run.tick(_at(80));
    expect(run.isFinished, isTrue);
    expect(run.isComplete, isTrue);
  });

  test('la pause gèle le minuteur', () {
    var run = WorkoutRun.start(const [_round], _t0);
    run = run.pause(_at(5));
    expect(run.tick(_at(100)).index, 0);
    expect(run.remaining(_at(100)), const Duration(seconds: 15));
    run = run.resume(_at(100));
    expect(run.remaining(_at(110)), const Duration(seconds: 5));
    run = run.tick(_at(115));
    expect(run.isFinished, isTrue);
  });

  test('passer un repos ne crée pas de résultat ; passer un effort, si', () {
    var run = WorkoutRun.start(const [_rest, _round], _t0);
    run = run.skip(_at(3));
    expect(run.results, isEmpty);
    run = run.skip(_at(4));
    expect(run.results.single.skipped, isTrue);
    expect(run.isFinished, isTrue);
    expect(run.isComplete, isFalse);
  });

  test('l’arrêt pour douleur conserve les efforts réalisés', () {
    var run = WorkoutRun.start(const [_round, _rest, _round], _t0);
    run = run.tick(_at(21)).stop(_at(22), StopReason.painOrDiscomfort);
    expect(run.isFinished, isTrue);
    expect(run.stopReason, StopReason.painOrDiscomfort);
    expect(run.results, hasLength(1));
    expect(run.isComplete, isFalse);
  });

  test('l’arrêt garde l’effort en attente d’intensité', () {
    var run = WorkoutRun.start(const [_set], _t0);
    run = run.completeWork(_at(10)).stop(_at(11), StopReason.userStopped);
    expect(run.results.single.reps, 10);
    expect(run.results.single.rpe, isNull);
  });

  test('une intensité de séance complète les efforts qui n’en ont pas', () {
    var run = WorkoutRun.start(const [_round, _round], _t0);
    run = run.tick(_at(40)).applySessionIntensity(6);
    expect([for (final r in run.results) r.rpe], [6, 6]);
  });

  test('annonce le prochain effort', () {
    final run = WorkoutRun.start(const [_set, _rest, _round], _t0);
    expect(run.nextWork, _round);
    expect(run.workStepCount, 2);
  });
}
