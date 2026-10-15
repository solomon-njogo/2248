part of '../resolve/resolve_engine.dart';

class _KeptRun {
  _KeptRun({
    required this.tiles,
    required this.score,
    required this.cleared,
    required this.chain,
  });

  final Map<Cell, int> tiles;
  final int score;
  final List<int> cleared;
  final List<Cell> chain;
}

class RunStore {
  _KeptRun? _run;

  void save(ResolveEngine engine) {
    _run = _KeptRun(
      tiles: Map<Cell, int>.of(engine._tiles),
      score: engine._score,
      cleared: List<int>.of(engine._cleared),
      chain: List<Cell>.of(engine._chain),
    );
  }

  bool load(ResolveEngine engine) {
    final run = _run;
    if (run == null) return false;
    engine._tiles
      ..clear()
      ..addAll(run.tiles);
    engine._score = run.score;
    engine._cleared
      ..clear()
      ..addAll(run.cleared);
    engine._chain
      ..clear()
      ..addAll(run.chain);
    return true;
  }
}
