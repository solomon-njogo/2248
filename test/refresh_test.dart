import 'package:flutter_test/flutter_test.dart';
import 'package:game_2248/resolve/resolve_engine.dart';

void main() {
  test('a pairless refresh keeps the one highest tile at column 3, row 4', () {
    final engine = ResolveEngine(
      script: [8, ...List.filled(39, 2), ...List.filled(39, 4)],
    );
    engine.place(_strictHighest());
    engine.seed(const Cell(1, 1), const Cell(2, 1));

    final report = engine.resolve();

    expect(report?.rawSum, 4);
    expect(report?.result, 4);
    expect(report?.head, const Cell(2, 1));
    expect(engine.score, 4);
    expect(engine.supply, [2, 4, 8]);
    expect(engine.cleared, isEmpty);
    expect(engine.chain, isEmpty);
    expect(engine.tileAt(const Cell(3, 4)), 2199023255552);
    for (var row = 1; row <= 8; row++) {
      for (var column = 1; column <= 5; column++) {
        if (column == 3 && row == 4) continue;
        expect(
          engine.tileAt(Cell(column, row)),
          2,
          reason: 'column $column, row $row',
        );
      }
    }
  });

  test('a refill that still has a pair stays where it fell', () {
    final engine = ResolveEngine(script: const [4]);
    engine.place(_strictHighest());
    engine.seed(const Cell(1, 1), const Cell(2, 1));

    final report = engine.resolve();

    expect(report?.rawSum, 4);
    expect(report?.result, 4);
    expect(report?.head, const Cell(2, 1));
    expect(engine.score, 4);
    expect(engine.supply, [2, 4, 8]);
    expect(engine.cleared, isEmpty);
    expect(engine.chain, isEmpty);
    expect(engine.tileAt(const Cell(1, 1)), 4);
    expect(engine.tileAt(const Cell(2, 1)), 4);
    expect(engine.tileAt(const Cell(3, 4)), 524288);
    expect(engine.tileAt(const Cell(5, 8)), 2199023255552);
    expect(engine.tileAt(const Cell(1, 8)), 137438953472);
    expect(engine.tileAt(const Cell(3, 1)), 16);
  });

  test(
    'tiles that share the highest value leave except one at column 3, row 4',
    () {
      final engine = ResolveEngine(script: [8, ...List.filled(39, 2)]);
      engine.place(_sharedHighest());
      engine.seed(const Cell(1, 1), const Cell(2, 1));

      engine.resolve();

      expect(engine.tileAt(const Cell(3, 4)), 4398046511104);
      expect(_copies(engine, 4398046511104), 1);
      expect(engine.score, 4);
      expect(engine.supply, [2, 4, 8]);
      expect(engine.cleared, isEmpty);
    },
  );

  test(
    'a scripted value outside the supply is skipped for the other 39 cells',
    () {
      final engine = ResolveEngine(
        script: [8, 16, 64, 7, ...List.filled(39, 4)],
      );
      engine.place(_strictHighest());
      engine.seed(const Cell(1, 1), const Cell(2, 1));

      engine.resolve();

      expect(engine.tileAt(const Cell(3, 4)), 2199023255552);
      for (var row = 1; row <= 8; row++) {
        for (var column = 1; column <= 5; column++) {
          if (column == 3 && row == 4) continue;
          expect(
            engine.tileAt(Cell(column, row)),
            4,
            reason: 'column $column, row $row',
          );
        }
      }
    },
  );

  test(
    'a refresh after a clear draws the new supply and clears nothing more',
    () {
      final engine = ResolveEngine(script: List.filled(40, 16));
      engine.place(_pairlessAcrossAClear());
      engine.seed(const Cell(1, 1), const Cell(2, 1));

      final report = engine.resolve();

      expect(report?.rawSum, 1024);
      expect(report?.result, 1024);
      expect(report?.head, const Cell(2, 1));
      expect(engine.score, 1024);
      expect(engine.cleared, [2]);
      expect(engine.supply, [4, 8, 16]);
      expect(engine.chain, isEmpty);
      expect(engine.tileAt(const Cell(3, 4)), 4398046511104);
      expect(_copies(engine, 4398046511104), 1);
      for (var row = 1; row <= 8; row++) {
        for (var column = 1; column <= 5; column++) {
          if (column == 3 && row == 4) continue;
          expect(
            engine.tileAt(Cell(column, row)),
            16,
            reason: 'column $column, row $row',
          );
        }
      }
    },
  );

  test('placing a pairless board leaves the highest tile where it was', () {
    final engine = ResolveEngine();

    expect(engine.place(_pairless()), isTrue);

    expect(engine.tileAt(const Cell(3, 4)), 524288);
    expect(engine.tileAt(const Cell(5, 8)), 2199023255552);
    expect(engine.score, 0);
    expect(engine.cleared, isEmpty);
    expect(engine.chain, isEmpty);
  });

  test('a dealt board has a pair and does not keep a placed highest tile', () {
    final engine = ResolveEngine();
    engine.place(const [Placement(3, 4, 1024), Placement(5, 8, 4096)]);

    engine.deal();

    expect(engine.score, 0);
    expect(engine.cleared, isEmpty);
    expect(engine.supply, [2, 4, 8]);
    expect(engine.chain, isEmpty);
    expect(engine.tileAt(const Cell(3, 4)), isNot(1024));
    expect(engine.tileAt(const Cell(5, 8)), isNot(4096));
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

List<Placement> _sharedHighest() {
  return [
    for (final placement in _strictHighest())
      if (placement.row == 8 &&
          (placement.column == 1 || placement.column == 5))
        Placement(placement.column, placement.row, 4398046511104)
      else
        placement,
  ];
}

List<Placement> _pairless() {
  return [
    for (final placement in _strictHighest())
      if (placement.column == 2 && placement.row == 1)
        const Placement(2, 1, 4)
      else
        placement,
  ];
}

List<Placement> _pairlessAcrossAClear() {
  const skip = {2, 16, 512, 1024};
  var power = 4;
  final placements = <Placement>[];
  for (var row = 1; row <= 8; row++) {
    for (var column = 1; column <= 5; column++) {
      if (row == 1 && (column == 1 || column == 2)) {
        placements.add(Placement(column, row, 512));
        continue;
      }
      while (skip.contains(power)) {
        power *= 2;
      }
      placements.add(Placement(column, row, power));
      power *= 2;
    }
  }
  return placements;
}

int _copies(ResolveEngine engine, int tile) {
  var copies = 0;
  for (var row = 1; row <= 8; row++) {
    for (var column = 1; column <= 5; column++) {
      if (engine.tileAt(Cell(column, row)) == tile) copies++;
    }
  }
  return copies;
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
