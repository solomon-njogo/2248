import 'dart:math';

class Cell {
  const Cell(this.column, this.row);

  final int column;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is Cell && other.column == column && other.row == row;

  @override
  int get hashCode => Object.hash(column, row);

  @override
  String toString() => 'Cell($column, $row)';
}

class Placement {
  const Placement(this.column, this.row, [this.tile]);

  final int column;
  final int row;
  final int? tile;
}

class ResolveReport {
  const ResolveReport({
    required this.rawSum,
    required this.result,
    required this.head,
  });

  final int rawSum;
  final int result;
  final Cell head;
}

class ResolveEngine {
  ResolveEngine({List<int> script = const []}) : _script = List<int>.of(script);

  final Map<Cell, int> _tiles = {};
  final List<Cell> _chain = [];
  final List<int> _script;
  final List<int> _cleared = [];
  final Random _random = Random();
  var _scriptCursor = 0;
  int _score = 0;

  int get score => _score;

  List<int> get supply {
    final values = <int>[];
    var value = 2;
    while (values.length < 3) {
      if (!_cleared.contains(value)) values.add(value);
      value *= 2;
    }
    return List.unmodifiable(values);
  }

  List<int> get cleared => List.unmodifiable(_cleared);

  bool place(List<Placement> placements) {
    final next = <Cell, int>{};
    final seen = <Cell>{};
    for (final placement in placements) {
      final cell = Cell(placement.column, placement.row);
      if (!_onBoard(cell)) return false;
      if (!seen.add(cell)) return false;
      final tile = placement.tile;
      if (tile == null) continue;
      if (!_isTile(tile)) return false;
      next[cell] = tile;
    }
    _tiles
      ..clear()
      ..addAll(next);
    _chain.clear();
    return true;
  }

  int? tileAt(Cell cell) => _tiles[cell];

  List<Cell> get chain => List.unmodifiable(_chain);

  bool seed(Cell start, Cell head) {
    final startTile = _tiles[start];
    final headTile = _tiles[head];
    if (startTile == null || headTile == null || startTile != headTile) {
      return false;
    }
    if (!_neighbors(start, head)) return false;
    _chain
      ..clear()
      ..add(start)
      ..add(head);
    return true;
  }

  ResolveReport? resolve() {
    if (_chain.isEmpty) return null;
    var rawSum = 0;
    for (final cell in _chain) {
      rawSum += _tiles[cell]!;
    }
    final result = _smallestPowerOfTwoAtLeast(rawSum);
    final head = _chain.last;
    for (final cell in _chain) {
      if (cell == head) {
        _tiles[cell] = result;
      } else {
        _tiles.remove(cell);
      }
    }
    _chain.clear();
    _clearCrossed(result);
    _score += rawSum;
    _fall();
    _refill();
    _refreshPairless();
    return ResolveReport(rawSum: rawSum, result: result, head: head);
  }

  void _refreshPairless() {
    if (_hasPair()) return;
    var highest = 0;
    for (final tile in _tiles.values) {
      if (tile > highest) highest = tile;
    }
    _tiles
      ..clear()
      ..[const Cell(3, 4)] = highest;
    do {
      for (var row = 1; row <= 8; row++) {
        for (var column = 1; column <= 5; column++) {
          if (column == 3 && row == 4) continue;
          _tiles[Cell(column, row)] = _nextFromSupply();
        }
      }
    } while (!_hasPair());
  }

  void _clearCrossed(int result) {
    final exponent = _exponent(result);
    if (exponent == null || exponent < 10) return;
    for (var rung = 10; rung <= exponent; rung++) {
      final value = 1 << (rung - 9);
      if (_cleared.contains(value)) continue;
      _cleared.add(value);
      final leaving = [
        for (final entry in _tiles.entries)
          if (entry.value == value) entry.key,
      ];
      for (final cell in leaving) {
        _tiles.remove(cell);
      }
    }
  }

  void _fall() {
    for (var column = 1; column <= 5; column++) {
      final survivors = <int>[];
      for (var row = 1; row <= 8; row++) {
        final tile = _tiles.remove(Cell(column, row));
        if (tile != null) survivors.add(tile);
      }
      final firstRow = 9 - survivors.length;
      for (var index = 0; index < survivors.length; index++) {
        _tiles[Cell(column, firstRow + index)] = survivors[index];
      }
    }
  }

  void _refill() {
    for (var row = 1; row <= 8; row++) {
      for (var column = 1; column <= 5; column++) {
        final cell = Cell(column, row);
        if (_tiles.containsKey(cell)) continue;
        _tiles[cell] = _nextFromSupply();
      }
    }
  }

  int _nextFromSupply() {
    while (_scriptCursor < _script.length) {
      final value = _script[_scriptCursor++];
      if (supply.contains(value)) return value;
    }
    final values = supply;
    return values[_random.nextInt(values.length)];
  }

  bool step(Cell cell) {
    if (_chain.isEmpty) return false;
    if (!_tiles.containsKey(cell)) return false;
    if (_chain.contains(cell)) return false;
    if (!_neighbors(_chain.last, cell)) return false;
    _chain.add(cell);
    return true;
  }

  void deal() {
    do {
      final next = <Cell, int>{};
      for (var row = 1; row <= 8; row++) {
        for (var column = 1; column <= 5; column++) {
          next[Cell(column, row)] = supply[_random.nextInt(supply.length)];
        }
      }
      _tiles
        ..clear()
        ..addAll(next);
    } while (!_hasPair());
    _chain.clear();
  }

  bool _hasPair() {
    final cells = _tiles.keys.toList();
    for (var i = 0; i < cells.length; i++) {
      for (var j = i + 1; j < cells.length; j++) {
        if (_tiles[cells[i]] == _tiles[cells[j]] &&
            _neighbors(cells[i], cells[j])) {
          return true;
        }
      }
    }
    return false;
  }
}

bool _isTile(int tile) => tile >= 2 && tile & (tile - 1) == 0;

int? _exponent(int value) {
  if (value < 2 || value & (value - 1) != 0) return null;
  var exponent = 0;
  var power = 1;
  while (power < value) {
    power *= 2;
    exponent++;
  }
  return exponent;
}

int _smallestPowerOfTwoAtLeast(int sum) {
  var power = 1;
  while (power < sum) {
    power *= 2;
  }
  return power;
}

bool _neighbors(Cell a, Cell b) {
  final columnDelta = (a.column - b.column).abs();
  final rowDelta = (a.row - b.row).abs();
  return columnDelta <= 1 &&
      rowDelta <= 1 &&
      (columnDelta != 0 || rowDelta != 0);
}

bool _onBoard(Cell cell) =>
    cell.column >= 1 && cell.column <= 5 && cell.row >= 1 && cell.row <= 8;
