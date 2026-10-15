import 'package:flutter_test/flutter_test.dart';
import 'package:game_2248/resolve/resolve_engine.dart';

void main() {
  test('a new engine starts with a score of 0', () {
    final engine = ResolveEngine();

    expect(engine.score, 0);
  });

  test('three 2s add 6 while the head becomes 8', () {
    final engine = ResolveEngine();
    engine.place(_filled(2));
    expect(engine.score, 0);
    _play(engine, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
    expect(engine.score, 0);

    final report = engine.resolve();

    expect(report?.rawSum, 6);
    expect(report?.result, 8);
    expect(report?.head, const Cell(3, 1));
    expect(engine.score, 6);
    expect(engine.tileAt(const Cell(3, 1)), 8);
  });

  test('five 2s add 10 while the head becomes 16', () {
    final engine = ResolveEngine();
    engine.place(_filled(2));
    _play(engine, const [
      Cell(1, 1),
      Cell(2, 1),
      Cell(3, 1),
      Cell(4, 1),
      Cell(5, 1),
    ]);
    expect(engine.score, 0);

    final report = engine.resolve();

    expect(report?.rawSum, 10);
    expect(report?.result, 16);
    expect(engine.score, 10);
    expect(engine.tileAt(const Cell(5, 1)), 16);
  });

  test('2 + 2 adds 4 while the head becomes 4', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(1, 1, 2), Placement(2, 1, 2)]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    expect(engine.score, 0);

    final report = engine.resolve();

    expect(report?.rawSum, 4);
    expect(report?.result, 4);
    expect(engine.score, 4);
    expect(engine.tileAt(const Cell(2, 1)), 4);
  });

  test('2 + 2 + 4 adds 8 while the head becomes 8', () {
    final engine = ResolveEngine();
    engine.place(const [
      Placement(1, 1, 2),
      Placement(2, 1, 2),
      Placement(3, 1, 4),
    ]);
    _play(engine, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
    expect(engine.score, 0);

    final report = engine.resolve();

    expect(report?.rawSum, 8);
    expect(report?.result, 8);
    expect(engine.score, 8);
    expect(engine.tileAt(const Cell(3, 1)), 8);
  });

  test('forty 2s add 80 while the head becomes 128', () {
    final engine = ResolveEngine();
    engine.place(_filled(2));
    final path = _serpentine();
    _play(engine, path);
    expect(engine.score, 0);

    final report = engine.resolve();

    expect(report?.rawSum, 80);
    expect(report?.result, 128);
    expect(report?.head, const Cell(1, 8));
    expect(engine.score, 80);
    expect(engine.tileAt(const Cell(1, 8)), 128);
  });

  test('the head tile is included once in the amount added', () {
    final engine = ResolveEngine();
    engine.place(const [
      Placement(1, 1, 2),
      Placement(2, 1, 2),
      Placement(3, 1, 4),
    ]);
    _play(engine, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
    expect(engine.score, 0);

    final report = engine.resolve();

    expect(report?.head, const Cell(3, 1));
    expect(report?.rawSum, 8);
    expect(engine.score, 8);
  });

  test('the same tiles add the same amount whichever cell is the head', () {
    final ontoThird = ResolveEngine();
    ontoThird.place(_filled(2));
    _play(ontoThird, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
    expect(ontoThird.score, 0);
    ontoThird.resolve();

    final ontoFirst = ResolveEngine();
    ontoFirst.place(_filled(2));
    _play(ontoFirst, const [Cell(3, 1), Cell(2, 1), Cell(1, 1)]);
    expect(ontoFirst.score, 0);
    ontoFirst.resolve();

    expect(ontoThird.score, 6);
    expect(ontoFirst.score, 6);
  });

  test('a second resolve adds its own raw sum on top', () {
    final engine = ResolveEngine();
    engine.place(_filled(2));
    _play(engine, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
    final first = engine.resolve();
    expect(first?.rawSum, 6);
    expect(engine.score, 6);

    _play(engine, const [
      Cell(1, 2),
      Cell(2, 2),
      Cell(3, 2),
      Cell(4, 2),
      Cell(5, 2),
    ]);
    expect(engine.score, 6);
    final second = engine.resolve();

    expect(second?.rawSum, 10);
    expect(engine.score, 16);
  });

  test('a resolve with no open chain leaves the score unchanged', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(1, 1, 2), Placement(2, 1, 2)]);
    expect(engine.score, 0);

    expect(engine.resolve(), isNull);
    expect(engine.score, 0);

    engine.seed(const Cell(1, 1), const Cell(2, 1));
    expect(engine.score, 0);
    expect(engine.resolve()?.rawSum, 4);
    expect(engine.score, 4);

    expect(engine.resolve(), isNull);
    expect(engine.score, 4);
  });

  test('a refused seed leaves the score unchanged', () {
    final engine = ResolveEngine();
    engine.place(const [
      Placement(1, 1, 2),
      Placement(2, 1, 2),
      Placement(1, 3, 2),
      Placement(2, 3, 4),
    ]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    engine.resolve();
    expect(engine.score, 4);

    expect(engine.seed(const Cell(1, 3), const Cell(2, 3)), isFalse);
    expect(engine.score, 4);
    expect(engine.seed(const Cell(1, 1), const Cell(1, 3)), isFalse);
    expect(engine.score, 4);
  });

  test('a refused step leaves the score unchanged', () {
    final engine = ResolveEngine();
    engine.place(const [
      Placement(1, 1, 2),
      Placement(2, 1, 2),
      Placement(4, 1, 8),
    ]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    expect(engine.score, 0);
    expect(engine.step(const Cell(4, 1)), isFalse);
    expect(engine.score, 0);

    engine.resolve();
    expect(engine.score, 4);
  });

  test('an accepted step leaves the score unchanged until resolve', () {
    final engine = ResolveEngine();
    engine.place(const [
      Placement(1, 1, 2),
      Placement(2, 1, 2),
      Placement(3, 1, 8),
    ]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    expect(engine.score, 0);

    expect(engine.step(const Cell(3, 1)), isTrue);
    expect(engine.score, 0);

    expect(engine.resolve()?.rawSum, 12);
    expect(engine.score, 12);
  });

  test(
    'a new seed that replaces an uncommitted chain leaves the score unchanged',
    () {
      final engine = ResolveEngine();
      engine.place(const [
        Placement(1, 1, 2),
        Placement(2, 1, 2),
        Placement(4, 4, 8),
        Placement(5, 5, 8),
      ]);
      engine.seed(const Cell(1, 1), const Cell(2, 1));
      engine.resolve();
      expect(engine.score, 4);

      expect(engine.seed(const Cell(4, 4), const Cell(5, 5)), isTrue);
      expect(engine.score, 4);
      expect(engine.seed(const Cell(4, 4), const Cell(5, 5)), isTrue);
      expect(engine.score, 4);
    },
  );

  test('placing a board leaves the score unchanged', () {
    final fresh = ResolveEngine();
    expect(fresh.score, 0);
    expect(fresh.place(const [Placement(1, 1, 2), Placement(2, 1, 4)]), isTrue);
    expect(fresh.score, 0);
    expect(fresh.place(const [Placement(1, 1, 3)]), isFalse);
    expect(fresh.score, 0);

    final earned = ResolveEngine();
    earned.place(const [Placement(1, 1, 2), Placement(2, 1, 2)]);
    earned.seed(const Cell(1, 1), const Cell(2, 1));
    earned.resolve();
    expect(earned.score, 4);

    expect(
      earned.place(const [Placement(3, 3, 8), Placement(4, 3, 16)]),
      isTrue,
    );
    expect(earned.score, 4);
    expect(earned.place(const [Placement(1, 1, 6)]), isFalse);
    expect(earned.score, 4);
  });

  test('dealing a board leaves the score unchanged', () {
    final fresh = ResolveEngine();
    expect(fresh.score, 0);
    fresh.deal();
    expect(fresh.score, 0);

    final earned = ResolveEngine();
    earned.place(const [Placement(1, 1, 2), Placement(2, 1, 2)]);
    earned.seed(const Cell(1, 1), const Cell(2, 1));
    earned.resolve();
    expect(earned.score, 4);

    earned.deal();
    expect(earned.score, 4);
  });

  test('a new engine starts at 0 when another engine already has a score', () {
    final scored = ResolveEngine();
    scored.place(const [Placement(1, 1, 2), Placement(2, 1, 2)]);
    scored.seed(const Cell(1, 1), const Cell(2, 1));
    scored.resolve();
    expect(scored.score, 4);

    expect(ResolveEngine().score, 0);
    expect(scored.score, 4);
  });

  test('the score keeps growing with no cap', () {
    final engine = ResolveEngine();
    engine.place(const [
      Placement(1, 1, 1073741824),
      Placement(2, 1, 1073741824),
      Placement(4, 1, 1073741824),
      Placement(5, 1, 1073741824),
    ]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    expect(engine.score, 0);
    expect(engine.resolve()?.rawSum, 2147483648);
    expect(engine.score, 2147483648);

    engine.seed(const Cell(4, 1), const Cell(5, 1));
    expect(engine.score, 2147483648);
    expect(engine.resolve()?.rawSum, 2147483648);
    expect(engine.score, 4294967296);
  });
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

void _play(ResolveEngine engine, List<Cell> cells) {
  expect(engine.seed(cells[0], cells[1]), isTrue);
  for (final cell in cells.skip(2)) {
    expect(engine.step(cell), isTrue, reason: '$cell');
  }
}

List<Placement> _filled(int tile) => [
  for (var row = 1; row <= 8; row++)
    for (var column = 1; column <= 5; column++) Placement(column, row, tile),
];
