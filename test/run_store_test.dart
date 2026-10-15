import 'package:flutter_test/flutter_test.dart';
import 'package:game_2248/resolve/resolve_engine.dart';

void main() {
  test(
    'a board with holes, a score, a clear, and an open chain survive in a new engine',
    () {
      final playing = _afterFirstClear();
      expect(
        playing.place(const [
          Placement(1, 1, 4),
          Placement(2, 1, 4),
          Placement(3, 1, 8),
          Placement(5, 8, 16),
        ]),
        isTrue,
      );
      expect(playing.seed(const Cell(1, 1), const Cell(2, 1)), isTrue);
      expect(playing.step(const Cell(3, 1)), isTrue);

      final store = RunStore();
      store.save(playing);

      final returned = ResolveEngine();
      returned.place(const [
        Placement(1, 1, 8),
        Placement(2, 1, 8),
        Placement(3, 4, 32),
      ]);
      returned.seed(const Cell(1, 1), const Cell(2, 1));

      expect(store.load(returned), isTrue);
      expect(returned.score, 1024);
      expect(returned.cleared, [2]);
      expect(returned.supply, [4, 8, 16]);
      expect(returned.chain, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
      expect(_board(returned), const [
        '4 4 8 . .',
        '. . . . .',
        '. . . . .',
        '. . . . .',
        '. . . . .',
        '. . . . .',
        '. . . . .',
        '. . . . 16',
      ]);
    },
  );

  test('a run with no open chain comes back with no open chain', () {
    final playing = _afterFirstClear();
    expect(playing.place(const [Placement(4, 6, 16)]), isTrue);

    final store = RunStore();
    store.save(playing);

    final returned = ResolveEngine();
    returned.place(const [Placement(1, 1, 8), Placement(2, 1, 8)]);
    expect(returned.seed(const Cell(1, 1), const Cell(2, 1)), isTrue);

    expect(store.load(returned), isTrue);
    expect(returned.chain, isEmpty);
    expect(returned.score, 1024);
    expect(returned.cleared, [2]);
    expect(returned.tileAt(const Cell(4, 6)), 16);
    expect(returned.tileAt(const Cell(1, 1)), isNull);
    expect(returned.tileAt(const Cell(2, 1)), isNull);
  });

  test('an empty store leaves the engine unchanged and keeps nothing', () {
    final store = RunStore();
    final playing = _afterFirstClear();
    expect(
      playing.place(const [
        Placement(1, 1, 4),
        Placement(2, 1, 4),
        Placement(5, 8, 16),
      ]),
      isTrue,
    );
    expect(playing.seed(const Cell(1, 1), const Cell(2, 1)), isTrue);

    expect(store.load(playing), isFalse);
    expect(playing.score, 1024);
    expect(playing.cleared, [2]);
    expect(playing.supply, [4, 8, 16]);
    expect(playing.chain, const [Cell(1, 1), Cell(2, 1)]);
    expect(_board(playing), const [
      '4 4 . . .',
      '. . . . .',
      '. . . . .',
      '. . . . .',
      '. . . . .',
      '. . . . .',
      '. . . . .',
      '. . . . 16',
    ]);
  });

  test('a second save replaces the stored run', () {
    final first = ResolveEngine();
    first.place(const [Placement(1, 1, 2), Placement(5, 8, 8)]);
    final store = RunStore();
    store.save(first);

    final second = _afterFirstClear();
    expect(second.place(const [Placement(3, 4, 16)]), isTrue);
    store.save(second);

    final returned = ResolveEngine();
    expect(store.load(returned), isTrue);
    expect(returned.score, 1024);
    expect(returned.cleared, [2]);
    expect(returned.supply, [4, 8, 16]);
    expect(returned.chain, isEmpty);
    expect(returned.tileAt(const Cell(3, 4)), 16);
    expect(returned.tileAt(const Cell(1, 1)), isNull);
    expect(returned.tileAt(const Cell(5, 8)), isNull);
  });

  test('a restored chain resolves and the score grows by its raw sum', () {
    final playing = _afterFirstClear();
    expect(
      playing.place(const [
        Placement(1, 1, 4),
        Placement(2, 1, 4),
        Placement(3, 1, 8),
      ]),
      isTrue,
    );
    expect(playing.seed(const Cell(1, 1), const Cell(2, 1)), isTrue);
    expect(playing.step(const Cell(3, 1)), isTrue);

    final store = RunStore();
    store.save(playing);

    final returned = ResolveEngine();
    expect(store.load(returned), isTrue);

    final report = returned.resolve();

    expect(report?.rawSum, 16);
    expect(report?.result, 16);
    expect(report?.head, const Cell(3, 1));
    expect(returned.score, 1040);
    expect(returned.chain, isEmpty);
  });

  test('two loads of one save show the same board and score', () {
    final playing = _afterFirstClear();
    expect(
      playing.place(const [
        Placement(1, 1, 4),
        Placement(2, 1, 4),
        Placement(3, 1, 8),
        Placement(5, 8, 16),
      ]),
      isTrue,
    );
    expect(playing.seed(const Cell(1, 1), const Cell(2, 1)), isTrue);
    expect(playing.step(const Cell(3, 1)), isTrue);

    final store = RunStore();
    store.save(playing);

    final firstLoad = ResolveEngine();
    expect(store.load(firstLoad), isTrue);
    expect(firstLoad.place(const [Placement(1, 1, 32)]), isTrue);

    final secondLoad = ResolveEngine();
    secondLoad.place(const [Placement(2, 2, 8), Placement(3, 3, 8)]);
    secondLoad.seed(const Cell(2, 2), const Cell(3, 3));
    expect(store.load(secondLoad), isTrue);

    expect(secondLoad.score, 1024);
    expect(secondLoad.cleared, [2]);
    expect(secondLoad.supply, [4, 8, 16]);
    expect(secondLoad.chain, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
    expect(_board(secondLoad), const [
      '4 4 8 . .',
      '. . . . .',
      '. . . . .',
      '. . . . .',
      '. . . . .',
      '. . . . .',
      '. . . . .',
      '. . . . 16',
    ]);
  });

  test('abandon then save then load keeps the new run', () {
    final playing = _afterFirstClear();
    expect(
      playing.place(const [
        Placement(1, 1, 16),
        Placement(2, 1, 16),
        Placement(3, 1, 32),
      ]),
      isTrue,
    );
    expect(playing.seed(const Cell(1, 1), const Cell(2, 1)), isTrue);
    expect(playing.step(const Cell(3, 1)), isTrue);
    playing.abandon();

    final store = RunStore();
    store.save(playing);

    final returned = _afterFirstClear();
    expect(store.load(returned), isTrue);

    expect(returned.score, 0);
    expect(returned.cleared, isEmpty);
    expect(returned.supply, [2, 4, 8]);
    expect(returned.chain, isEmpty);
    expect(_board(returned), _board(playing));
    for (final row in _board(returned)) {
      for (final tile in row.split(' ')) {
        expect(tile, isIn(['2', '4', '8']));
      }
    }
  });

  test('a resolve after a save is absent until the next save', () {
    final playing = _afterFirstClear(script: List.filled(80, 4));
    expect(
      playing.place(const [
        Placement(1, 1, 4),
        Placement(2, 1, 4),
        Placement(3, 1, 8),
      ]),
      isTrue,
    );
    expect(playing.seed(const Cell(1, 1), const Cell(2, 1)), isTrue);
    expect(playing.step(const Cell(3, 1)), isTrue);

    final store = RunStore();
    store.save(playing);
    final report = playing.resolve();
    expect(report?.rawSum, 16);
    expect(playing.score, 1040);

    final returned = ResolveEngine();
    expect(store.load(returned), isTrue);
    expect(returned.score, 1024);
    expect(returned.cleared, [2]);
    expect(returned.chain, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
    expect(_board(returned), const [
      '4 4 8 . .',
      '. . . . .',
      '. . . . .',
      '. . . . .',
      '. . . . .',
      '. . . . .',
      '. . . . .',
      '. . . . .',
    ]);

    store.save(playing);
    final later = ResolveEngine();
    expect(store.load(later), isTrue);
    expect(later.score, 1040);
    expect(later.cleared, [2]);
    expect(later.chain, isEmpty);
    expect(later.tileAt(const Cell(3, 8)), 16);
    expect(later.tileAt(const Cell(1, 1)), 4);
  });
}

ResolveEngine _afterFirstClear({List<int> script = const []}) {
  final engine = ResolveEngine(script: script);
  engine.place(const [Placement(1, 1, 512), Placement(2, 1, 512)]);
  engine.seed(const Cell(1, 1), const Cell(2, 1));
  engine.resolve();
  return engine;
}

List<String> _board(ResolveEngine engine) => [
  for (var row = 1; row <= 8; row++)
    [
      for (var column = 1; column <= 5; column++)
        engine.tileAt(Cell(column, row))?.toString() ?? '.',
    ].join(' '),
];
