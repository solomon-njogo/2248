part of '../resolve/resolve_engine.dart';

abstract class RunArchive {
  String? read();

  void write(String payload);
}

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

  Map<String, Object?> toJson() => {
    'score': score,
    'cleared': cleared,
    'chain': [
      for (final cell in chain) {'column': cell.column, 'row': cell.row},
    ],
    'tiles': [
      for (final entry in tiles.entries)
        {'column': entry.key.column, 'row': entry.key.row, 'tile': entry.value},
    ],
  };

  static _KeptRun decode(String payload) {
    final json = jsonDecode(payload);
    if (json is! Map) {
      throw const FormatException('run');
    }
    final tiles = <Cell, int>{};
    for (final entry in json['tiles'] as List) {
      final tile = entry as Map;
      tiles[Cell(tile['column'] as int, tile['row'] as int)] =
          tile['tile'] as int;
    }
    final chain = [
      for (final entry in json['chain'] as List)
        Cell((entry as Map)['column'] as int, entry['row'] as int),
    ];
    return _KeptRun(
      tiles: tiles,
      score: json['score'] as int,
      cleared: [for (final value in json['cleared'] as List) value as int],
      chain: chain,
    );
  }
}

class RunStore {
  RunStore({RunArchive? archive}) : _archive = archive {
    final payload = archive?.read();
    if (payload == null || payload.isEmpty) return;
    try {
      _run = _KeptRun.decode(payload);
    } on FormatException {
      _run = null;
    }
  }

  final RunArchive? _archive;
  _KeptRun? _run;

  void save(ResolveEngine engine) {
    _run = _KeptRun(
      tiles: Map<Cell, int>.of(engine._tiles),
      score: engine._score,
      cleared: List<int>.of(engine._cleared),
      chain: List<Cell>.of(engine._chain),
    );
    _archive?.write(jsonEncode(_run!.toJson()));
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
