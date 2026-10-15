import 'package:flutter_test/flutter_test.dart';
import 'package:game_2248/resolve/resolve_engine.dart';

void main() {
  test(
    'abandoning discards the score, the clears, and the open chain for a new opening board',
    () {
      final engine = ResolveEngine();
      engine.place(const [Placement(1, 1, 512), Placement(2, 1, 512)]);
      engine.seed(const Cell(1, 1), const Cell(2, 1));
      final report = engine.resolve();
      expect(report?.rawSum, 1024);
      expect(report?.result, 1024);
      expect(report?.head, const Cell(2, 1));
      expect(engine.score, 1024);
      expect(engine.cleared, [2]);
      expect(engine.supply, [4, 8, 16]);

      expect(
        engine.place(const [
          Placement(1, 1, 16),
          Placement(2, 1, 16),
          Placement(3, 1, 32),
        ]),
        isTrue,
      );
      expect(engine.seed(const Cell(1, 1), const Cell(2, 1)), isTrue);
      expect(engine.step(const Cell(3, 1)), isTrue);
      expect(engine.chain, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
      expect(engine.score, 1024);
      expect(engine.cleared, [2]);

      engine.abandon();

      expect(report?.rawSum, 1024);
      expect(report?.result, 1024);
      expect(report?.head, const Cell(2, 1));
      expect(engine.score, 0);
      expect(engine.cleared, isEmpty);
      expect(engine.supply, [2, 4, 8]);
      expect(engine.chain, isEmpty);
      for (var row = 1; row <= 8; row++) {
        for (var column = 1; column <= 5; column++) {
          expect(
            engine.tileAt(Cell(column, row)),
            isIn([2, 4, 8]),
            reason: 'column $column, row $row',
          );
        }
      }
      expect(_hasPair(engine), isTrue);
    },
  );

  test('a resolve after abandon adds only that chain\'s raw sum', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(1, 1, 512), Placement(2, 1, 512)]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    engine.resolve();
    expect(engine.score, 1024);
    expect(engine.cleared, [2]);

    expect(
      engine.place(const [
        Placement(1, 1, 16),
        Placement(2, 1, 16),
        Placement(3, 1, 32),
      ]),
      isTrue,
    );
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    engine.step(const Cell(3, 1));
    engine.abandon();
    expect(engine.score, 0);

    expect(
      engine.place(const [
        Placement(1, 1, 2),
        Placement(2, 1, 2),
        Placement(3, 1, 4),
      ]),
      isTrue,
    );
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    engine.step(const Cell(3, 1));

    final report = engine.resolve();

    expect(report?.rawSum, 8);
    expect(report?.result, 8);
    expect(report?.head, const Cell(3, 1));
    expect(engine.score, 8);
    expect(engine.cleared, isEmpty);
    expect(engine.supply, [2, 4, 8]);
  });

  test('a 2 on the new run stays until the first 1024 removes every 2', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(1, 1, 512), Placement(2, 1, 512)]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    engine.resolve();
    expect(engine.score, 1024);
    expect(engine.cleared, [2]);
    expect(engine.supply, [4, 8, 16]);

    engine.abandon();
    expect(engine.score, 0);
    expect(engine.cleared, isEmpty);
    expect(engine.supply, [2, 4, 8]);

    expect(
      engine.place(const [
        Placement(1, 1, 4),
        Placement(2, 1, 4),
        Placement(5, 8, 2),
      ]),
      isTrue,
    );
    engine.seed(const Cell(1, 1), const Cell(2, 1));

    final kept = engine.resolve();

    expect(kept?.rawSum, 8);
    expect(kept?.result, 8);
    expect(engine.score, 8);
    expect(engine.cleared, isEmpty);
    expect(engine.supply, [2, 4, 8]);
    expect(engine.tileAt(const Cell(5, 8)), 2);

    expect(
      engine.place(const [
        Placement(1, 1, 512),
        Placement(2, 1, 512),
        Placement(3, 1, 2),
        Placement(4, 8, 2),
      ]),
      isTrue,
    );
    engine.seed(const Cell(1, 1), const Cell(2, 1));

    final cleared = engine.resolve();

    expect(cleared?.rawSum, 1024);
    expect(cleared?.result, 1024);
    expect(cleared?.head, const Cell(2, 1));
    expect(engine.score, 1032);
    expect(engine.cleared, [2]);
    expect(engine.supply, [4, 8, 16]);
    for (var row = 1; row <= 8; row++) {
      for (var column = 1; column <= 5; column++) {
        expect(
          engine.tileAt(Cell(column, row)),
          isNot(2),
          reason: 'column $column, row $row',
        );
      }
    }
  });

  test('a second abandon returns to the same opening state', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(1, 1, 512), Placement(2, 1, 512)]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    engine.resolve();
    engine.place(const [Placement(1, 1, 8), Placement(2, 1, 8)]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    engine.abandon();
    expect(engine.score, 0);
    expect(engine.cleared, isEmpty);
    expect(engine.supply, [2, 4, 8]);

    expect(
      engine.place(const [Placement(1, 1, 512), Placement(2, 1, 512)]),
      isTrue,
    );
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    engine.resolve();
    expect(engine.score, 1024);
    expect(engine.cleared, [2]);
    expect(engine.supply, [4, 8, 16]);
    expect(
      engine.place(const [Placement(1, 1, 16), Placement(2, 1, 16)]),
      isTrue,
    );
    expect(engine.seed(const Cell(1, 1), const Cell(2, 1)), isTrue);

    engine.abandon();

    expect(engine.score, 0);
    expect(engine.cleared, isEmpty);
    expect(engine.supply, [2, 4, 8]);
    expect(engine.chain, isEmpty);
    for (var row = 1; row <= 8; row++) {
      for (var column = 1; column <= 5; column++) {
        expect(
          engine.tileAt(Cell(column, row)),
          isIn([2, 4, 8]),
          reason: 'column $column, row $row',
        );
      }
    }
    expect(_hasPair(engine), isTrue);
  });

  test(
    'a refresh of a pairless aftermath leaves the score and the cleared values',
    () {
      final engine = ResolveEngine(
        script: [...List.filled(39, 4), 8, ...List.filled(39, 4)],
      );
      engine.place(const [Placement(1, 1, 512), Placement(2, 1, 512)]);
      engine.seed(const Cell(1, 1), const Cell(2, 1));
      engine.resolve();
      expect(engine.score, 1024);
      expect(engine.cleared, [2]);
      expect(engine.supply, [4, 8, 16]);

      expect(engine.place(_strictHighest()), isTrue);
      engine.seed(const Cell(1, 1), const Cell(2, 1));

      final report = engine.resolve();

      expect(report?.rawSum, 4);
      expect(report?.result, 4);
      expect(engine.score, 1028);
      expect(engine.cleared, [2]);
      expect(engine.supply, [4, 8, 16]);
      expect(engine.chain, isEmpty);
      expect(engine.tileAt(const Cell(3, 4)), 2199023255552);
    },
  );

  test('placing or dealing leaves the score and the cleared values', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(1, 1, 512), Placement(2, 1, 512)]);
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    engine.resolve();
    expect(engine.score, 1024);
    expect(engine.cleared, [2]);
    expect(engine.supply, [4, 8, 16]);

    expect(
      engine.place(const [Placement(1, 1, 4), Placement(2, 1, 8)]),
      isTrue,
    );
    expect(engine.score, 1024);
    expect(engine.cleared, [2]);
    expect(engine.supply, [4, 8, 16]);
    expect(engine.tileAt(const Cell(1, 1)), 4);
    expect(engine.tileAt(const Cell(2, 1)), 8);

    engine.deal();

    expect(engine.score, 1024);
    expect(engine.cleared, [2]);
    expect(engine.supply, [4, 8, 16]);
    expect(engine.chain, isEmpty);
    for (var row = 1; row <= 8; row++) {
      for (var column = 1; column <= 5; column++) {
        expect(
          engine.tileAt(Cell(column, row)),
          isIn([4, 8, 16]),
          reason: 'column $column, row $row',
        );
      }
    }
    expect(_hasPair(engine), isTrue);
  });
}

List<Placement> _strictHighest() {
  var power = 16;
  final placements = <Placement>[];
  for (var row = 1; row <= 8; row++) {
    for (var column = 1; column <= 5; column++) {
      if (row == 1 && (column == 1 || column == 2)) {
        placements.add(Placement(column, row, 2));
      } else {
        placements.add(Placement(column, row, power));
        power *= 2;
      }
    }
  }
  return placements;
}

bool _hasPair(ResolveEngine engine) {
  for (var row = 1; row <= 8; row++) {
    for (var column = 1; column <= 5; column++) {
      final tile = engine.tileAt(Cell(column, row));
      if (tile == null) continue;
      for (var otherRow = row; otherRow <= 8; otherRow++) {
        for (var otherColumn = 1; otherColumn <= 5; otherColumn++) {
          if (otherRow == row && otherColumn <= column) continue;
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
