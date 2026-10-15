import 'package:flutter_test/flutter_test.dart';
import 'package:game_2248/resolve/resolve_engine.dart';

void main() {
  test('a hole in the middle of a column closes against the floor', () {
    final engine = ResolveEngine(script: const [2]);
    engine.place(
      _placed(const [
        '2 2 4 4 4',
        '4 4 4 4 4',
        '16 2 4 4 4',
        '8 8 4 4 4',
        '32 4 4 4 4',
        '64 2 4 4 4',
        '128 4 4 4 4',
        '256 2 4 4 4',
      ]),
    );
    engine.seed(const Cell(1, 4), const Cell(2, 4));

    final report = engine.resolve();

    expect(report?.rawSum, 16);
    expect(report?.result, 16);
    expect(report?.head, const Cell(2, 4));
    expect(_board(engine), const [
      '2 2 4 4 4',
      '2 4 4 4 4',
      '4 2 4 4 4',
      '16 16 4 4 4',
      '32 4 4 4 4',
      '64 2 4 4 4',
      '128 4 4 4 4',
      '256 2 4 4 4',
    ]);
  });

  test(
    'a hole at the top of a packed column leaves the tiles where they are',
    () {
      final engine = ResolveEngine(script: const [8, 4]);
      engine.place(
        _placed(const [
          '. 4 4 2 2',
          '2 4 4 4 4',
          '4 4 4 4 4',
          '8 4 4 4 4',
          '16 4 4 4 4',
          '32 4 4 4 4',
          '64 4 4 4 4',
          '128 4 4 4 4',
        ]),
      );
      engine.seed(const Cell(4, 1), const Cell(5, 1));

      final report = engine.resolve();

      expect(report?.result, 4);
      expect(report?.head, const Cell(5, 1));
      expect(_board(engine), const [
        '8 4 4 4 4',
        '2 4 4 4 4',
        '4 4 4 4 4',
        '8 4 4 4 4',
        '16 4 4 4 4',
        '32 4 4 4 4',
        '64 4 4 4 4',
        '128 4 4 4 4',
      ]);
    },
  );

  test('a column that lost no tile stays put while its neighbor falls', () {
    final engine = ResolveEngine(script: const [2]);
    engine.place(
      _placed(const [
        '2 8 4 4 4',
        '4 16 4 4 4',
        '8 32 4 4 4',
        '16 16 4 4 4',
        '32 128 4 4 4',
        '64 256 4 4 4',
        '128 512 4 4 4',
        '256 1024 4 4 4',
      ]),
    );
    engine.seed(const Cell(1, 4), const Cell(2, 4));

    engine.resolve();

    expect(_board(engine), const [
      '2 8 4 4 4',
      '2 16 4 4 4',
      '4 32 4 4 4',
      '8 32 4 4 4',
      '32 128 4 4 4',
      '64 256 4 4 4',
      '128 512 4 4 4',
      '256 1024 4 4 4',
    ]);
  });

  test('a full column that the chain missed is unchanged', () {
    final engine = ResolveEngine(script: const [4]);
    engine.place(
      _placed(const [
        '2 4 4 4 2',
        '2 4 4 4 4',
        '2 4 4 4 8',
        '2 4 4 4 16',
        '2 4 4 4 32',
        '2 4 4 4 64',
        '2 4 4 4 128',
        '2 4 4 4 256',
      ]),
    );
    engine.seed(const Cell(1, 1), const Cell(1, 2));

    engine.resolve();

    expect(_board(engine), const [
      '4 4 4 4 2',
      '4 4 4 4 4',
      '2 4 4 4 8',
      '2 4 4 4 16',
      '2 4 4 4 32',
      '2 4 4 4 64',
      '2 4 4 4 128',
      '2 4 4 4 256',
    ]);
  });

  test('the result rests lower than the head cell named in the report', () {
    final engine = ResolveEngine(script: const [2, 4, 8, 2, 4, 8, 2]);
    engine.place(
      _placed(const [
        '8 4 4 4 4',
        '8 4 4 4 4',
        '. 4 4 4 4',
        '. 4 4 4 4',
        '. 4 4 4 4',
        '. 4 4 4 4',
        '. 4 4 4 4',
        '. 4 4 4 4',
      ]),
    );
    engine.seed(const Cell(1, 1), const Cell(1, 2));

    final report = engine.resolve();

    expect(report?.rawSum, 16);
    expect(report?.result, 16);
    expect(report?.head, const Cell(1, 2));
    expect(engine.tileAt(const Cell(1, 2)), 4);
    expect(engine.tileAt(const Cell(1, 8)), 16);
    expect(_board(engine), const [
      '2 4 4 4 4',
      '4 4 4 4 4',
      '8 4 4 4 4',
      '2 4 4 4 4',
      '4 4 4 4 4',
      '8 4 4 4 4',
      '2 4 4 4 4',
      '16 4 4 4 4',
    ]);
  });

  test(
    'a column that held chain tiles and not the head is filled from the supply',
    () {
      final engine = ResolveEngine(script: const [2, 4, 8, 2, 4, 8, 2, 4]);
      engine.place(
        _placed(const [
          '2 4 4 4 4',
          '2 4 4 4 4',
          '2 4 4 4 4',
          '2 4 4 4 4',
          '2 4 4 4 4',
          '2 4 4 4 4',
          '2 4 4 4 4',
          '2 2 4 4 4',
        ]),
      );
      _play(engine, const [
        Cell(1, 1),
        Cell(1, 2),
        Cell(1, 3),
        Cell(1, 4),
        Cell(1, 5),
        Cell(1, 6),
        Cell(1, 7),
        Cell(1, 8),
        Cell(2, 8),
      ]);

      final report = engine.resolve();

      expect(report?.rawSum, 18);
      expect(report?.result, 32);
      expect(report?.head, const Cell(2, 8));
      expect(_board(engine), const [
        '2 4 4 4 4',
        '4 4 4 4 4',
        '8 4 4 4 4',
        '2 4 4 4 4',
        '4 4 4 4 4',
        '8 4 4 4 4',
        '2 4 4 4 4',
        '4 32 4 4 4',
      ]);
    },
  );

  test(
    'a scripted refill of 2, 4, and 8 fills the holes from the top left',
    () {
      final engine = ResolveEngine(script: const [2, 4, 8]);
      engine.place(_placed(_rowsOf('2 2 2 2 2')));
      _play(engine, const [Cell(1, 1), Cell(2, 1), Cell(3, 1), Cell(4, 1)]);

      final report = engine.resolve();

      expect(report?.rawSum, 8);
      expect(report?.result, 8);
      expect(report?.head, const Cell(4, 1));
      expect(_board(engine).first, '2 4 8 8 2');
      for (final row in _board(engine).skip(1)) {
        expect(row, '2 2 2 2 2');
      }
    },
  );

  test('a scripted value outside the supply is skipped', () {
    final engine = ResolveEngine(script: const [2, 16, 4, 3, 8, 7]);
    engine.place(_placed(_rowsOf('2 2 2 2 2')));
    _play(engine, const [Cell(1, 1), Cell(2, 1), Cell(3, 1), Cell(4, 1)]);

    engine.resolve();

    expect(_board(engine).first, '2 4 8 8 2');
  });

  test('holes past the end of the script are filled from the supply', () {
    final engine = ResolveEngine(script: const [2]);
    engine.place(_placed(_rowsOf('2 2 2 2 2')));
    _play(engine, const [Cell(1, 1), Cell(2, 1), Cell(3, 1), Cell(4, 1)]);

    engine.resolve();

    expect(engine.tileAt(const Cell(1, 1)), 2);
    expect(engine.tileAt(const Cell(2, 1)), isIn([2, 4, 8]));
    expect(engine.tileAt(const Cell(3, 1)), isIn([2, 4, 8]));
    expect(engine.tileAt(const Cell(4, 1)), 8);
    expect(engine.tileAt(const Cell(5, 1)), 2);
  });

  test('a chain through several columns falls in each of those columns', () {
    final engine = ResolveEngine(script: const [4, 8]);
    engine.place(
      _placed(const [
        '2 4 4 4 4',
        '4 2 8 4 4',
        '8 8 2 4 4',
        '16 16 16 4 4',
        '32 32 32 4 4',
        '64 64 64 4 4',
        '128 128 128 4 4',
        '256 256 256 4 4',
      ]),
    );
    _play(engine, const [Cell(1, 1), Cell(2, 2), Cell(3, 3)]);

    final report = engine.resolve();

    expect(report?.rawSum, 6);
    expect(report?.result, 8);
    expect(report?.head, const Cell(3, 3));
    expect(_board(engine), const [
      '4 8 4 4 4',
      '4 4 8 4 4',
      '8 8 8 4 4',
      '16 16 16 4 4',
      '32 32 32 4 4',
      '64 64 64 4 4',
      '128 128 128 4 4',
      '256 256 256 4 4',
    ]);
  });

  test('a pair can be seeded on the closed board', () {
    final engine = ResolveEngine(script: const [8, 8]);
    engine.place(_placed(_rowsOf('2 2 2 2 2')));
    _play(engine, const [Cell(3, 1), Cell(4, 1), Cell(5, 1)]);

    engine.resolve();

    expect(engine.tileAt(const Cell(3, 1)), 8);
    expect(engine.tileAt(const Cell(4, 1)), 8);
    expect(engine.seed(const Cell(3, 1), const Cell(4, 1)), isTrue);
    expect(engine.chain, const [Cell(3, 1), Cell(4, 1)]);
  });

  test('a later resolve continues the scripted sequence', () {
    final engine = ResolveEngine(script: const [2, 8, 4]);
    engine.place(_placed(_rowsOf('2 2 2 2 2')));
    engine.seed(const Cell(5, 1), const Cell(4, 1));

    engine.resolve();

    expect(engine.tileAt(const Cell(5, 1)), 2);
    expect(engine.tileAt(const Cell(4, 1)), 4);
    _play(engine, const [Cell(1, 2), Cell(2, 2), Cell(3, 2)]);
    final report = engine.resolve();

    expect(report?.result, 8);
    expect(engine.tileAt(const Cell(1, 1)), 8);
    expect(engine.tileAt(const Cell(2, 1)), 4);
    expect(engine.tileAt(const Cell(3, 2)), 8);
    expect(engine.tileAt(const Cell(5, 1)), 2);
  });

  test('a refused resolve leaves every tile where it is', () {
    final engine = ResolveEngine(script: const [2, 4, 8]);
    engine.place(
      _placed(const [
        '2 . 8 4 4',
        '4 16 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
      ]),
    );
    final before = _board(engine);

    expect(engine.resolve(), isNull);

    expect(_board(engine), before);
    expect(engine.tileAt(const Cell(2, 1)), isNull);
  });

  test('a refused seed leaves a placed hole empty', () {
    final engine = ResolveEngine(script: const [2]);
    engine.place(
      _placed(const [
        '2 2 . 4 4',
        '4 4 4 4 4',
        '8 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
      ]),
    );

    expect(engine.seed(const Cell(1, 1), const Cell(1, 2)), isFalse);

    expect(engine.tileAt(const Cell(3, 1)), isNull);
    expect(engine.tileAt(const Cell(1, 1)), 2);
    expect(engine.tileAt(const Cell(1, 3)), 8);
    expect(engine.chain, isEmpty);
  });

  test('a refused step leaves every tile where it is', () {
    final engine = ResolveEngine(script: const [2, 4, 8]);
    engine.place(
      _placed(const [
        '4 4 . 8 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
      ]),
    );
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    final before = _board(engine);

    expect(engine.step(const Cell(4, 1)), isFalse);

    expect(_board(engine), before);
    expect(engine.chain, const [Cell(1, 1), Cell(2, 1)]);
  });

  test('a placed hole stays empty until a resolve', () {
    final engine = ResolveEngine(script: const [8]);
    engine.place(
      _placed(const [
        '2 4 4 4 4',
        '16 . 4 4 4',
        '8 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
      ]),
    );

    expect(engine.tileAt(const Cell(2, 2)), isNull);
    expect(engine.tileAt(const Cell(1, 1)), 2);
    expect(engine.tileAt(const Cell(1, 2)), 16);
    expect(engine.tileAt(const Cell(1, 3)), 8);
  });

  test('a dealt board fills every cell from the supply', () {
    final engine = ResolveEngine(script: const [2, 4, 8]);
    engine.place(
      _placed(const [
        '256 4 4 4 4',
        '. 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
        '4 4 4 4 4',
      ]),
    );

    engine.deal();

    for (var row = 1; row <= 8; row++) {
      for (var column = 1; column <= 5; column++) {
        expect(
          engine.tileAt(Cell(column, row)),
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

List<String> _rowsOf(String row) => List.filled(8, row);

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

List<String> _board(ResolveEngine engine) => [
  for (var row = 1; row <= 8; row++)
    [
      for (var column = 1; column <= 5; column++)
        engine.tileAt(Cell(column, row))?.toString() ?? '.',
    ].join(' '),
];
