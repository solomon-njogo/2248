import 'package:flutter_test/flutter_test.dart';
import 'package:game_2248/resolve/resolve_engine.dart';

void main() {
  test('a new run supplies 2, 4, and 8 and has cleared nothing', () {
    final engine = ResolveEngine();

    expect(engine.supply, [2, 4, 8]);
    expect(engine.cleared, isEmpty);
  });

  test('forty 2s resolve to 128 and clear nothing', () {
    final engine = ResolveEngine();
    engine.place(_filled(2));
    _play(engine, _serpentine());

    final report = engine.resolve();

    expect(report?.rawSum, 80);
    expect(report?.result, 128);
    expect(engine.score, 80);
    expect(engine.supply, [2, 4, 8]);
    expect(engine.cleared, isEmpty);
  });

  test('a result of 512 clears nothing', () {
    final engine = ResolveEngine();
    engine.place(
      _placed(const [
        '256 256 2 4 8',
        '4 4 4 4 4',
        '8 8 8 8 8',
        '4 4 4 4 4',
        '8 8 8 8 8',
        '4 4 4 4 4',
        '8 8 8 8 8',
        '4 4 4 4 4',
      ]),
    );
    engine.seed(const Cell(1, 1), const Cell(2, 1));

    final report = engine.resolve();

    expect(report?.rawSum, 512);
    expect(report?.result, 512);
    expect(engine.score, 512);
    expect(engine.tileAt(const Cell(3, 1)), 2);
    expect(engine.supply, [2, 4, 8]);
    expect(engine.cleared, isEmpty);
  });

  test(
    'the first 1024 removes every 2 and the supply becomes 4, 8, and 16',
    () {
      final engine = ResolveEngine(script: const [2, 4, 8, 16]);
      engine.place(
        _placed(const [
          '512 512 2 4 8',
          '2 4 4 8 16',
          '4 8 8 16 32',
          '8 16 16 32 4',
          '16 32 32 4 8',
          '32 4 4 8 16',
          '4 8 8 16 32',
          '8 16 16 32 4',
        ]),
      );
      engine.seed(const Cell(1, 1), const Cell(2, 1));

      final report = engine.resolve();

      expect(report?.rawSum, 1024);
      expect(report?.result, 1024);
      expect(report?.head, const Cell(2, 1));
      expect(engine.score, 1024);
      expect(engine.cleared, [2]);
      expect(engine.supply, [4, 8, 16]);
      expect(engine.tileAt(const Cell(2, 1)), 1024);
      expect(_board(engine), const [
        '4 1024 8 4 8',
        '16 4 4 8 16',
        '4 8 8 16 32',
        '8 16 16 32 4',
        '16 32 32 4 8',
        '32 4 4 8 16',
        '4 8 8 16 32',
        '8 16 16 32 4',
      ]);
    },
  );

  test('the first 2048 removes every 2 and every 4', () {
    final engine = ResolveEngine(script: const [2, 4, 8, 16, 32, 8, 16, 32]);
    engine.place(
      _placed(const [
        '1024 1024 2 4 8',
        '2 4 8 16 32',
        '4 8 16 32 8',
        '8 16 32 8 16',
        '16 32 8 16 32',
        '32 8 16 32 8',
        '8 16 32 8 16',
        '16 32 8 16 32',
      ]),
    );
    engine.seed(const Cell(1, 1), const Cell(2, 1));

    final report = engine.resolve();

    expect(report?.rawSum, 2048);
    expect(report?.result, 2048);
    expect(engine.score, 2048);
    expect(engine.cleared, [2, 4]);
    expect(engine.supply, [8, 16, 32]);
    expect(_board(engine), const [
      '8 16 32 8 8',
      '16 2048 8 16 32',
      '32 8 16 32 8',
      '8 16 32 8 16',
      '16 32 8 16 32',
      '32 8 16 32 8',
      '8 16 32 8 16',
      '16 32 8 16 32',
    ]);
  });

  test('the first 4096 removes every 2, every 4, and every 8', () {
    final engine = ResolveEngine(script: const [2, 4, 8, 16, 32, 64, 16]);
    engine.place(
      _placed(const [
        '2048 2048 2 4 8',
        '16 16 16 16 16',
        '16 16 16 16 16',
        '16 16 16 16 16',
        '16 16 16 16 16',
        '16 16 16 16 16',
        '16 16 16 16 16',
        '16 16 16 16 16',
      ]),
    );
    engine.seed(const Cell(1, 1), const Cell(2, 1));

    final report = engine.resolve();

    expect(report?.rawSum, 4096);
    expect(report?.result, 4096);
    expect(engine.score, 4096);
    expect(engine.cleared, [2, 4, 8]);
    expect(engine.supply, [16, 32, 64]);
    expect(engine.tileAt(const Cell(2, 1)), 4096);
    expect(_board(engine).first, '16 4096 32 64 16');
    for (final row in _board(engine).skip(1)) {
      expect(row, '16 16 16 16 16');
    }
  });

  test('a second 1024 removes nothing further', () {
    final engine = ResolveEngine(script: const [4, 8, 16, 4]);
    engine.place(_rows(const ['512 512 4 8 16']));
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    expect(engine.resolve()?.result, 1024);
    expect(engine.score, 1024);
    expect(engine.cleared, [2]);

    expect(
      engine.place(
        _placed(const [
          '512 512 2 4 8',
          '2 4 8 16 32',
          '4 8 16 32 4',
          '8 16 32 4 8',
          '16 32 4 8 16',
          '32 4 8 16 32',
          '4 8 16 32 4',
          '8 16 32 4 8',
        ]),
      ),
      isTrue,
    );
    expect(engine.cleared, [2]);
    expect(engine.supply, [4, 8, 16]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));

    final report = engine.resolve();

    expect(report?.rawSum, 1024);
    expect(report?.result, 1024);
    expect(engine.score, 2048);
    expect(engine.cleared, [2]);
    expect(engine.supply, [4, 8, 16]);
    expect(engine.tileAt(const Cell(2, 1)), 1024);
    expect(engine.tileAt(const Cell(3, 1)), 2);
    expect(engine.tileAt(const Cell(1, 2)), 2);
  });

  test('a 2048 after 2s were cleared removes 4s only', () {
    final engine = ResolveEngine(script: const [4, 8, 16]);
    engine.place(_rows(const ['512 512 4 4 4']));
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    expect(engine.resolve()?.rawSum, 1024);
    expect(engine.cleared, [2]);

    engine.place(_rows(const ['1024 1024 2 4 16']));
    engine.seed(const Cell(1, 1), const Cell(2, 1));

    final report = engine.resolve();

    expect(report?.rawSum, 2048);
    expect(report?.result, 2048);
    expect(engine.score, 3072);
    expect(engine.cleared, [2, 4]);
    expect(engine.supply, [8, 16, 32]);
    expect(engine.tileAt(const Cell(2, 1)), 2048);
    expect(engine.tileAt(const Cell(3, 1)), 2);
    expect(engine.tileAt(const Cell(4, 1)), 16);
    expect(_board(engine).first, '8 2048 2 16 16');
  });

  test('a 2 placed after 2s were cleared survives a later resolve', () {
    final engine = ResolveEngine(script: const [2, 4]);
    engine.place(_rows(const ['512 512 8 8 8']));
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    engine.resolve();
    expect(engine.cleared, [2]);
    expect(engine.score, 1024);

    engine.place(_rows(const ['4 4 2 8 16']));
    engine.seed(const Cell(1, 1), const Cell(2, 1));

    final report = engine.resolve();

    expect(report?.rawSum, 8);
    expect(report?.result, 8);
    expect(engine.score, 1032);
    expect(engine.cleared, [2]);
    expect(engine.supply, [4, 8, 16]);
    expect(engine.tileAt(const Cell(2, 1)), 8);
    expect(engine.tileAt(const Cell(3, 1)), 2);
  });

  test('a 2 taken by the chain still counts in the raw sum', () {
    final engine = ResolveEngine(script: const [8, 16, 32, 8]);
    engine.place(
      _placed(const [
        '512 512 2 4 8',
        '2 8 8 8 8',
        '8 8 8 8 8',
        '8 8 8 8 8',
        '8 8 8 8 8',
        '8 8 8 8 8',
        '8 8 8 8 8',
        '8 8 8 8 8',
      ]),
    );
    _play(engine, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);

    final report = engine.resolve();

    expect(report?.rawSum, 1026);
    expect(report?.result, 2048);
    expect(engine.score, 1026);
    expect(engine.cleared, [2, 4]);
    expect(engine.supply, [8, 16, 32]);
    expect(engine.tileAt(const Cell(3, 1)), 2048);
    expect(_values(engine), isNot(contains(2)));
    expect(_values(engine), isNot(contains(4)));
  });

  test('an 8192 after 4096 removes 16s only', () {
    final engine = ResolveEngine(script: const [16, 32, 64]);
    engine.place(_rows(const ['2048 2048 16 16 16']));
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    expect(engine.resolve()?.result, 4096);
    expect(engine.cleared, [2, 4, 8]);
    expect(engine.supply, [16, 32, 64]);

    engine.place(_rows(const ['4096 4096 16 32 64']));
    engine.seed(const Cell(1, 1), const Cell(2, 1));

    final report = engine.resolve();

    expect(report?.rawSum, 8192);
    expect(report?.result, 8192);
    expect(engine.score, 12288);
    expect(engine.cleared, [2, 4, 8, 16]);
    expect(engine.supply, [32, 64, 128]);
    expect(engine.tileAt(const Cell(2, 1)), 8192);
    expect(engine.tileAt(const Cell(4, 1)), 32);
    expect(_board(engine).first, '32 8192 64 32 64');
  });

  test('a deal after 2s are cleared uses only 4, 8, and 16 and has a pair', () {
    final engine = ResolveEngine();
    engine.place(_rows(const ['512 512 2 2 2']));
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    engine.resolve();
    expect(engine.score, 1024);
    expect(engine.supply, [4, 8, 16]);

    engine.deal();

    expect(engine.score, 1024);
    expect(engine.cleared, [2]);
    expect(engine.supply, [4, 8, 16]);
    expect(_hasPair(engine), isTrue);
    for (var row = 1; row <= 8; row++) {
      for (var column = 1; column <= 5; column++) {
        expect(
          engine.tileAt(Cell(column, row)),
          isIn([4, 8, 16]),
          reason: 'column $column, row $row',
        );
      }
    }
  });

  test('placing or dealing a board clears nothing', () {
    final placed = ResolveEngine();
    expect(
      placed.place(const [
        Placement(1, 1, 4096),
        Placement(2, 1, 2),
        Placement(3, 1, 4),
        Placement(4, 1, 8),
      ]),
      isTrue,
    );

    expect(placed.score, 0);
    expect(placed.cleared, isEmpty);
    expect(placed.supply, [2, 4, 8]);
    expect(placed.tileAt(const Cell(1, 1)), 4096);
    expect(placed.tileAt(const Cell(2, 1)), 2);

    final dealt = ResolveEngine();
    dealt.deal();

    expect(dealt.score, 0);
    expect(dealt.cleared, isEmpty);
    expect(dealt.supply, [2, 4, 8]);
    for (var row = 1; row <= 8; row++) {
      for (var column = 1; column <= 5; column++) {
        expect(
          dealt.tileAt(Cell(column, row)),
          isIn([2, 4, 8]),
          reason: 'column $column, row $row',
        );
      }
    }
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

List<Placement> _rows(List<String> top) {
  final rows = [...top];
  while (rows.length < 8) {
    rows.add(rows.last);
  }
  return _placed(rows);
}

Set<int> _values(ResolveEngine engine) => {
  for (var row = 1; row <= 8; row++)
    for (var column = 1; column <= 5; column++)
      if (engine.tileAt(Cell(column, row)) != null)
        engine.tileAt(Cell(column, row))!,
};

bool _hasPair(ResolveEngine engine) {
  for (var row = 1; row <= 8; row++) {
    for (var column = 1; column <= 5; column++) {
      final tile = engine.tileAt(Cell(column, row));
      if (tile == null) continue;
      for (var otherRow = 1; otherRow <= 8; otherRow++) {
        for (var otherColumn = 1; otherColumn <= 5; otherColumn++) {
          if (otherRow == row && otherColumn == column) continue;
          final columnDelta = (column - otherColumn).abs();
          final rowDelta = (row - otherRow).abs();
          if (columnDelta > 1 || rowDelta > 1) continue;
          if (engine.tileAt(Cell(otherColumn, otherRow)) == tile) return true;
        }
      }
    }
  }
  return false;
}

List<Placement> _filled(int tile) => [
  for (var row = 1; row <= 8; row++)
    for (var column = 1; column <= 5; column++) Placement(column, row, tile),
];

List<String> _board(ResolveEngine engine) => [
  for (var row = 1; row <= 8; row++)
    [
      for (var column = 1; column <= 5; column++)
        engine.tileAt(Cell(column, row))?.toString() ?? '.',
    ].join(' '),
];

List<Placement> _placed(List<String> rows) {
  final placements = <Placement>[];
  for (var row = 0; row < rows.length; row++) {
    final tokens = rows[row].split(' ');
    for (var column = 0; column < tokens.length; column++) {
      if (tokens[column] == '.') continue;
      placements.add(Placement(column + 1, row + 1, int.parse(tokens[column])));
    }
  }
  return placements;
}
