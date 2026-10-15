import 'package:flutter_test/flutter_test.dart';
import 'package:game_2248/resolve/resolve_engine.dart';

void main() {
  test(
    'a placed board is read with column 1 at the left and row 1 at the top',
    () {
      final engine = ResolveEngine();

      final placed = engine.place(const [
        Placement(1, 1, 2),
        Placement(5, 1, 4),
        Placement(1, 8, 8),
        Placement(5, 8, 16),
      ]);

      expect(placed, isTrue);
      expect(engine.tileAt(const Cell(1, 1)), 2);
      expect(engine.tileAt(const Cell(5, 1)), 4);
      expect(engine.tileAt(const Cell(1, 8)), 8);
      expect(engine.tileAt(const Cell(5, 8)), 16);
      expect(engine.tileAt(const Cell(3, 4)), isNull);
    },
  );

  test('a tile that is not a power of 2 from 2 upward is rejected', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(1, 1, 2)]);

    for (final tile in [1, 3, 6, 0, -2]) {
      final placed = engine.place(
        const [
          Placement(1, 1, 2),
          Placement(2, 1, 4),
        ].followedBy([Placement(3, 1, tile)]).toList(),
      );

      expect(placed, isFalse, reason: 'tile $tile');
      expect(engine.tileAt(const Cell(1, 1)), 2, reason: 'tile $tile');
      expect(engine.tileAt(const Cell(2, 1)), isNull, reason: 'tile $tile');
    }
  });

  test('a cell given more than one tile is rejected', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(1, 1, 8)]);

    final placed = engine.place(const [Placement(1, 1, 2), Placement(1, 1, 4)]);

    expect(placed, isFalse);
    expect(engine.tileAt(const Cell(1, 1)), 8);
  });

  test('a cell off the 5 by 8 board is rejected', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(2, 2, 4)]);

    for (final placement in const [
      Placement(0, 1, 2),
      Placement(6, 1, 2),
      Placement(1, 0, 2),
      Placement(1, 9, 2),
    ]) {
      final placed = engine.place([placement]);

      expect(
        placed,
        isFalse,
        reason: 'column ${placement.column}, row ${placement.row}',
      );
      expect(
        engine.tileAt(const Cell(2, 2)),
        4,
        reason: 'column ${placement.column}, row ${placement.row}',
      );
    }
  });

  test('a dealt board fills every cell with a tile from the supply', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(3, 4, 16)]);

    engine.deal();

    for (var row = 1; row <= 8; row++) {
      for (var column = 1; column <= 5; column++) {
        final tile = engine.tileAt(Cell(column, row));
        expect(tile, isNotNull, reason: 'column $column, row $row');
        expect(tile, isIn([2, 4, 8]), reason: 'column $column, row $row');
      }
    }
  });

  test(
    'an equal pair that shares a side seeds an ordered chain headed by the second tile',
    () {
      final engine = ResolveEngine();
      engine.place(const [Placement(1, 1, 2), Placement(2, 1, 2)]);

      expect(engine.chain, isEmpty);
      expect(engine.seed(const Cell(1, 1), const Cell(2, 1)), isTrue);
      expect(engine.chain, const [Cell(1, 1), Cell(2, 1)]);
      expect(engine.tileAt(const Cell(1, 1)), 2);
      expect(engine.tileAt(const Cell(2, 1)), 2);
    },
  );

  test(
    'two equal tiles that are not neighbors are refused and leave the open chain',
    () {
      final engine = ResolveEngine();
      engine.place(const [
        Placement(1, 1, 2),
        Placement(2, 1, 2),
        Placement(1, 3, 2),
      ]);
      engine.seed(const Cell(1, 1), const Cell(2, 1));

      final refused = engine.seed(const Cell(1, 1), const Cell(1, 3));

      expect(refused, isFalse);
      expect(engine.chain, const [Cell(1, 1), Cell(2, 1)]);
      expect(engine.tileAt(const Cell(1, 1)), 2);
      expect(engine.tileAt(const Cell(2, 1)), 2);
      expect(engine.tileAt(const Cell(1, 3)), 2);
    },
  );

  test('two neighboring tiles of different values are refused', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(1, 1, 2), Placement(2, 1, 4)]);

    expect(engine.seed(const Cell(1, 1), const Cell(2, 1)), isFalse);
    expect(engine.chain, isEmpty);
    expect(engine.tileAt(const Cell(1, 1)), 2);
    expect(engine.tileAt(const Cell(2, 1)), 4);
  });

  test('a seed on an empty cell is refused', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(1, 1, 2)]);

    expect(engine.seed(const Cell(1, 1), const Cell(2, 1)), isFalse);
    expect(engine.seed(const Cell(2, 1), const Cell(3, 1)), isFalse);
    expect(engine.chain, isEmpty);
    expect(engine.tileAt(const Cell(1, 1)), 2);
    expect(engine.tileAt(const Cell(2, 1)), isNull);
  });

  test('an equal pair that shares a corner seeds a chain', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(2, 2, 8), Placement(3, 3, 8)]);

    expect(engine.seed(const Cell(2, 2), const Cell(3, 3)), isTrue);
    expect(engine.chain, const [Cell(2, 2), Cell(3, 3)]);
  });

  test(
    'a corner cell has three neighbors, an edge five, and an interior eight',
    () {
      final engine = ResolveEngine();
      engine.place(_filled(2));

      expect(_seedTargets(engine, const Cell(1, 1)), 3);
      expect(_seedTargets(engine, const Cell(5, 8)), 3);
      expect(_seedTargets(engine, const Cell(3, 1)), 5);
      expect(_seedTargets(engine, const Cell(1, 4)), 5);
      expect(_seedTargets(engine, const Cell(3, 4)), 8);
      expect(_seedTargets(engine, const Cell(2, 7)), 8);
    },
  );

  test('a legal seed replaces an uncommitted chain and leaves every tile', () {
    final engine = ResolveEngine();
    engine.place(const [
      Placement(1, 1, 2),
      Placement(2, 1, 2),
      Placement(4, 4, 8),
      Placement(5, 5, 8),
    ]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));

    expect(engine.seed(const Cell(4, 4), const Cell(5, 5)), isTrue);
    expect(engine.chain, const [Cell(4, 4), Cell(5, 5)]);
    expect(engine.tileAt(const Cell(1, 1)), 2);
    expect(engine.tileAt(const Cell(2, 1)), 2);
    expect(engine.tileAt(const Cell(4, 4)), 8);
    expect(engine.tileAt(const Cell(5, 5)), 8);
  });

  test('a placed board replaces any open chain', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(1, 1, 2), Placement(2, 1, 2)]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));

    expect(
      engine.place(const [Placement(1, 1, 2), Placement(2, 1, 2)]),
      isTrue,
    );
    expect(engine.chain, isEmpty);
    expect(engine.tileAt(const Cell(1, 1)), 2);
    expect(engine.tileAt(const Cell(2, 1)), 2);
  });

  test('a refused place leaves the open chain', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(1, 1, 2), Placement(2, 1, 2)]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));

    expect(engine.place(const [Placement(1, 1, 3)]), isFalse);
    expect(engine.chain, const [Cell(1, 1), Cell(2, 1)]);
    expect(engine.tileAt(const Cell(1, 1)), 2);
    expect(engine.tileAt(const Cell(2, 1)), 2);
  });

  test('a dealt board replaces any open chain', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(1, 1, 2), Placement(2, 1, 2)]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));

    engine.deal();

    expect(engine.chain, isEmpty);
  });

  test('a dealt board has at least one pair', () {
    final engine = ResolveEngine();
    engine.deal();

    expect(_seedsAPair(engine), isTrue);
  });

  test('a step onto a neighboring tile of any value becomes the head', () {
    final engine = ResolveEngine();
    engine.place(const [
      Placement(1, 1, 2),
      Placement(2, 1, 2),
      Placement(3, 1, 256),
    ]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));

    expect(engine.step(const Cell(3, 1)), isTrue);

    expect(engine.chain, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
    expect(engine.tileAt(const Cell(1, 1)), 2);
    expect(engine.tileAt(const Cell(2, 1)), 2);
    expect(engine.tileAt(const Cell(3, 1)), 256);
  });

  test('a step before any seed is refused', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(1, 1, 2)]);

    expect(engine.step(const Cell(1, 1)), isFalse);
    expect(engine.chain, isEmpty);
    expect(engine.tileAt(const Cell(1, 1)), 2);
  });

  test('a step that does not neighbor the head is refused', () {
    final engine = ResolveEngine();
    engine.place(const [
      Placement(1, 1, 2),
      Placement(2, 1, 2),
      Placement(3, 1, 4),
      Placement(1, 2, 8),
    ]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    expect(engine.step(const Cell(3, 1)), isTrue);
    final before = _snapshot(engine);

    expect(engine.step(const Cell(1, 2)), isFalse);

    expect(engine.chain, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
    expect(_snapshot(engine), before);
  });

  test('a step onto a cell already in the chain is refused', () {
    final engine = ResolveEngine();
    engine.place(_filled(2));
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    final beforeSeedStep = _snapshot(engine);

    expect(engine.step(const Cell(1, 1)), isFalse);
    expect(engine.chain, const [Cell(1, 1), Cell(2, 1)]);
    expect(_snapshot(engine), beforeSeedStep);

    expect(engine.step(const Cell(3, 1)), isTrue);
    final beforeRepeat = _snapshot(engine);
    expect(engine.step(const Cell(2, 1)), isFalse);
    expect(engine.chain, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
    expect(_snapshot(engine), beforeRepeat);
  });

  test('a step onto an empty cell or off the board is refused', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(1, 1, 4), Placement(2, 1, 4)]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    final before = _snapshot(engine);

    expect(engine.step(const Cell(3, 1)), isFalse);
    expect(engine.step(const Cell(2, 0)), isFalse);
    expect(engine.chain, const [Cell(1, 1), Cell(2, 1)]);
    expect(_snapshot(engine), before);
  });

  test(
    'a diagonal step from a high tile onto a lower tile joins the chain',
    () {
      final engine = ResolveEngine();
      engine.place(const [
        Placement(1, 1, 256),
        Placement(2, 1, 256),
        Placement(1, 2, 2),
      ]);
      engine.seed(const Cell(1, 1), const Cell(2, 1));

      expect(engine.step(const Cell(1, 2)), isTrue);
      expect(engine.chain, const [Cell(1, 1), Cell(2, 1), Cell(1, 2)]);
      expect(engine.tileAt(const Cell(1, 2)), 2);
    },
  );

  test('a seed of two 2s resolves to 4 on the head', () {
    final engine = ResolveEngine();
    engine.place(const [
      Placement(1, 1, 2),
      Placement(2, 1, 2),
      Placement(5, 8, 8),
    ]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));

    final report = engine.resolve();

    expect(report?.rawSum, 4);
    expect(report?.result, 4);
    expect(report?.head, const Cell(2, 1));
    expect(engine.tileAt(const Cell(2, 1)), 4);
    expect(engine.tileAt(const Cell(1, 1)), isNull);
    expect(engine.tileAt(const Cell(5, 8)), 8);
    expect(engine.chain, isEmpty);
  });

  test('2 + 2 + 4 resolves to 8 and includes the head', () {
    final engine = ResolveEngine();
    engine.place(const [
      Placement(1, 1, 2),
      Placement(2, 1, 2),
      Placement(3, 1, 4),
      Placement(4, 1),
      Placement(5, 5, 32),
    ]);
    _play(engine, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);

    final report = engine.resolve();

    expect(report?.rawSum, 8);
    expect(report?.result, 8);
    expect(report?.head, const Cell(3, 1));
    expect(engine.tileAt(const Cell(3, 1)), 8);
    expect(engine.tileAt(const Cell(1, 1)), isNull);
    expect(engine.tileAt(const Cell(2, 1)), isNull);
    expect(engine.tileAt(const Cell(4, 1)), isNull);
    expect(engine.tileAt(const Cell(5, 5)), 32);
    expect(engine.chain, isEmpty);
  });

  test('three 2s resolve to 8 and five 2s resolve to 16', () {
    final three = ResolveEngine();
    three.place(_filled(2));
    _play(three, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
    final threeReport = three.resolve();
    expect(threeReport?.rawSum, 6);
    expect(threeReport?.result, 8);
    expect(three.tileAt(const Cell(3, 1)), 8);
    expect(three.tileAt(const Cell(1, 2)), 2);

    final five = ResolveEngine();
    five.place(_filled(2));
    _play(five, const [
      Cell(1, 1),
      Cell(2, 1),
      Cell(3, 1),
      Cell(4, 1),
      Cell(5, 1),
    ]);
    final fiveReport = five.resolve();
    expect(fiveReport?.rawSum, 10);
    expect(fiveReport?.result, 16);
    expect(five.tileAt(const Cell(5, 1)), 16);
    expect(five.tileAt(const Cell(1, 1)), isNull);
    expect(five.tileAt(const Cell(1, 2)), 2);
  });

  test(
    'forty 2s resolve to 128 on the head and leave the other cells empty',
    () {
      final engine = ResolveEngine();
      engine.place(_filled(2));
      final path = _serpentine();
      _play(engine, path);

      final report = engine.resolve();

      expect(report?.rawSum, 80);
      expect(report?.result, 128);
      expect(report?.head, const Cell(1, 8));
      for (final cell in path) {
        expect(
          engine.tileAt(cell),
          cell == path.last ? 128 : isNull,
          reason: 'column ${cell.column}, row ${cell.row}',
        );
      }
      expect(engine.chain, isEmpty);
    },
  );

  test('the same tiles write the result on whichever cell is the head', () {
    final ontoSecond = ResolveEngine();
    ontoSecond.place(const [Placement(1, 1, 2), Placement(1, 2, 2)]);
    ontoSecond.seed(const Cell(1, 1), const Cell(1, 2));
    expect(ontoSecond.resolve()?.head, const Cell(1, 2));
    expect(ontoSecond.tileAt(const Cell(1, 2)), 4);
    expect(ontoSecond.tileAt(const Cell(1, 1)), isNull);

    final ontoFirst = ResolveEngine();
    ontoFirst.place(const [Placement(1, 1, 2), Placement(1, 2, 2)]);
    ontoFirst.seed(const Cell(1, 2), const Cell(1, 1));
    expect(ontoFirst.resolve()?.head, const Cell(1, 1));
    expect(ontoFirst.tileAt(const Cell(1, 1)), 4);
    expect(ontoFirst.tileAt(const Cell(1, 2)), isNull);
  });

  test('a resolve with no open chain reports nothing and changes nothing', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(1, 1, 2), Placement(2, 1, 2)]);

    expect(engine.resolve(), isNull);
    expect(engine.tileAt(const Cell(1, 1)), 2);
    expect(engine.tileAt(const Cell(2, 1)), 2);
    expect(engine.chain, isEmpty);

    engine.seed(const Cell(1, 1), const Cell(2, 1));
    engine.resolve();
    final after = _snapshot(engine);

    expect(engine.resolve(), isNull);
    expect(_snapshot(engine), after);
    expect(engine.chain, isEmpty);
  });

  test(
    'a later chain can step onto a result and a remaining pair can still seed',
    () {
      final engine = ResolveEngine();
      engine.place(_filled(2));
      _play(engine, const [
        Cell(1, 1),
        Cell(2, 1),
        Cell(3, 1),
        Cell(4, 1),
        Cell(5, 1),
      ]);
      expect(engine.resolve()?.result, 16);
      expect(engine.tileAt(const Cell(1, 1)), isNull);
      expect(engine.tileAt(const Cell(2, 1)), isNull);

      expect(engine.seed(const Cell(4, 2), const Cell(5, 2)), isTrue);
      expect(engine.step(const Cell(5, 1)), isTrue);
      final report = engine.resolve();
      expect(report?.rawSum, 20);
      expect(report?.result, 32);
      expect(engine.tileAt(const Cell(5, 1)), 32);
      expect(engine.tileAt(const Cell(4, 2)), isNull);
      expect(engine.tileAt(const Cell(5, 2)), isNull);
      expect(engine.tileAt(const Cell(1, 1)), isNull);
      expect(engine.chain, isEmpty);
    },
  );

  test('two equal tiles separated by an empty cell are refused as a seed', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(1, 1, 4), Placement(1, 3, 4)]);

    expect(engine.seed(const Cell(1, 1), const Cell(1, 3)), isFalse);
    expect(engine.chain, isEmpty);
    expect(engine.tileAt(const Cell(1, 1)), 4);
    expect(engine.tileAt(const Cell(1, 2)), isNull);
    expect(engine.tileAt(const Cell(1, 3)), 4);
  });
}

void _play(ResolveEngine engine, List<Cell> cells) {
  expect(engine.seed(cells[0], cells[1]), isTrue);
  for (final cell in cells.skip(2)) {
    expect(engine.step(cell), isTrue, reason: '$cell');
  }
}

List<Cell> _serpentine() {
  final cells = <Cell>[];
  for (var row = 1; row <= 8; row++) {
    final columns = row.isOdd ? [1, 2, 3, 4, 5] : [5, 4, 3, 2, 1];
    for (final column in columns) {
      cells.add(Cell(column, row));
    }
  }
  return cells;
}

List<int?> _snapshot(ResolveEngine engine) => [
  for (var row = 1; row <= 8; row++)
    for (var column = 1; column <= 5; column++)
      engine.tileAt(Cell(column, row)),
];

List<Placement> _filled(int tile) => [
  for (var row = 1; row <= 8; row++)
    for (var column = 1; column <= 5; column++) Placement(column, row, tile),
];

bool _seedsAPair(ResolveEngine engine) {
  for (var row = 1; row <= 8; row++) {
    for (var column = 1; column <= 5; column++) {
      if (_seedTargets(engine, Cell(column, row)) > 0) return true;
    }
  }
  return false;
}

int _seedTargets(ResolveEngine engine, Cell origin) {
  var count = 0;
  for (var row = 1; row <= 8; row++) {
    for (var column = 1; column <= 5; column++) {
      if (engine.seed(origin, Cell(column, row))) count++;
    }
  }
  return count;
}
