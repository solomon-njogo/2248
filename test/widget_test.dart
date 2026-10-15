import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_2248/cues/cues.dart';
import 'package:game_2248/main.dart';
import 'package:game_2248/play/play_screen.dart';
import 'package:game_2248/resolve/resolve_engine.dart';
import 'package:game_2248/run/sound_memory.dart';

void testPlay(String description, WidgetTesterCallback body) {
  testWidgets(description, (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await body(tester);
    } finally {
      handle.dispose();
    }
  });
}

void main() {
  testPlay('the open run is the whole screen', (tester) async {
    final engine = ResolveEngine();
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues);

    expect(find.text('Hello World'), findsNothing);
    expect(find.text('2248'), findsOneWidget);
    expect(find.text('ABANDON'), findsOneWidget);
    expect(find.byTooltip('Mute'), findsOneWidget);
    expect(supplyLabel(tester), '2, 4, 8');
    expect(scoreFigure(tester), '0');
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      const Color(0xff1a1464),
    );

    var tiles = 0;
    var pair = false;
    for (var row = 1; row <= 8; row++) {
      for (var column = 1; column <= 5; column++) {
        final text = numeral(tester, Cell(column, row));
        expect(text, isIn(['2', '4', '8']));
        tiles++;
        if (text != null && _neighborMatches(tester, column, row, text)) {
          pair = true;
        }
      }
    }
    expect(tiles, 40);
    expect(pair, isTrue);
    expect(cues.events, isEmpty);
  });

  testPlay('tiles, wells, and the floor use the night ladder', (tester) async {
    final engine = placed(
      fill: 4,
      tiles: {Cell(1, 1): 2, Cell(2, 1): 8, Cell(3, 1): 64},
      holes: {Cell(5, 1), Cell(5, 8)},
    );
    await pumpPlay(tester, engine: engine);

    expect(wellColor(tester, 5, 1), const Color(0xff24185a));
    expect(wellColor(tester, 5, 8), const Color(0xff1a1048));
    expect(tileColorOf(tester, const Cell(1, 1)), const Color(0xffff2d8a));
    expect(numeralColor(tester, const Cell(1, 1)), const Color(0xffffffff));
    expect(tileColorOf(tester, const Cell(2, 1)), const Color(0xffc6f22a));
    expect(numeralColor(tester, const Cell(2, 1)), const Color(0xff1a1a2e));
    expect(tileColorOf(tester, const Cell(3, 1)), const Color(0xffffe14a));
    expect(numeralColor(tester, const Cell(3, 1)), const Color(0xff1a1a2e));
    expect(numeral(tester, const Cell(5, 1)), isNull);
  });

  testPlay('a chain shows its colors, the pending head, and a connector', (
    tester,
  ) async {
    final engine = placed(
      fill: 4,
      tiles: {Cell(2, 2): 8, Cell(3, 3): 8, Cell(1, 1): 2, Cell(2, 1): 2},
    );
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues);

    final gesture = await holdChain(tester, const [Cell(2, 2), Cell(3, 3)]);

    expect(numeral(tester, const Cell(2, 2)), '8');
    expect(numeral(tester, const Cell(3, 3)), '16');
    expect(tileColorOf(tester, const Cell(2, 2)), const Color(0xffc6f22a));
    expect(tileColorOf(tester, const Cell(3, 3)), const Color(0xffff7a18));
    expect(rimWidth(tester, const Cell(2, 2)), 6);
    expect(rimWidth(tester, const Cell(3, 3)), 6);
    expect(find.byKey(const ValueKey('chain-connector')), findsOneWidget);
    expect(find.bySemanticsLabel('8, in the chain'), findsOneWidget);
    expect(find.bySemanticsLabel('16'), findsOneWidget);
    expect(cues.events, [const Cue.step(67, tone: true)]);
    expect(engine.score, 0);

    await gesture.up();
  });

  testPlay('a mouse drag seeds the same chain as a finger', (tester) async {
    final engine = placed(fill: 4, tiles: {Cell(1, 1): 2, Cell(2, 1): 2});
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues);

    final gesture = await holdChain(tester, const [
      Cell(1, 1),
      Cell(2, 1),
    ], kind: PointerDeviceKind.mouse);

    expect(numeral(tester, const Cell(2, 1)), '4');
    expect(cues.events, [const Cue.step(62, tone: true)]);
    await gesture.up();
  });

  testPlay('a drag that is not an equal pair plays nothing', (tester) async {
    final engine = placed(fill: 8, tiles: {Cell(1, 1): 2, Cell(2, 1): 4});
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues);

    await dragChain(tester, const [Cell(1, 1), Cell(2, 1)]);

    expect(engine.chain, isEmpty);
    expect(cues.events, isEmpty);
    expect(numeral(tester, const Cell(1, 1)), '2');
    expect(numeral(tester, const Cell(2, 1)), '4');
    expect(scoreFigure(tester), '0');
  });

  testPlay('lifting with no chain changes nothing', (tester) async {
    final engine = placed(fill: 2);
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues);

    await tester.tap(find.byKey(const ValueKey(Cell(1, 1))));
    await tester.pump();

    expect(engine.chain, isEmpty);
    expect(engine.score, 0);
    expect(cues.events, isEmpty);
  });

  testPlay('a second finger does not draw a chain', (tester) async {
    final engine = placed(fill: 2);
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues);

    final first = await tester.startGesture(centerOf(tester, const Cell(1, 1)));
    final second = await tester.startGesture(
      centerOf(tester, const Cell(4, 4)),
    );
    await second.moveTo(centerOf(tester, const Cell(5, 5)));
    await tester.pump();
    await second.up();
    await first.up();
    await tester.pump();

    expect(engine.chain, isEmpty);
    expect(cues.events, isEmpty);
  });

  testPlay('a long press does not resolve', (tester) async {
    final engine = placed(fill: 2);
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues);

    final gesture = await tester.startGesture(
      centerOf(tester, const Cell(2, 1)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.up();
    await tester.pump();

    expect(engine.chain, const [Cell(1, 1), Cell(2, 1)]);
    expect(engine.score, 0);
    expect(cues.events, isEmpty);
  });

  testPlay('step, retract, and a refused earlier cell', (tester) async {
    final engine = placed(fill: 2);
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues);

    final gesture = await holdChain(tester, const [
      Cell(1, 1),
      Cell(2, 1),
      Cell(3, 1),
      Cell(4, 1),
    ]);
    expect(cues.events, const [
      Cue.step(62, tone: true),
      Cue.step(64, tone: true),
      Cue.step(64, tone: true),
    ]);
    expect(numeral(tester, const Cell(4, 1)), '8');

    await gesture.moveTo(centerOf(tester, const Cell(3, 1)));
    await tester.pump();
    expect(engine.chain, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
    expect(numeral(tester, const Cell(3, 1)), '8');
    expect(cues.events.last, const Cue.step(64, tone: true));

    final cuesBeforeRefusal = cues.events.length;
    await gesture.moveTo(centerOf(tester, const Cell(1, 1)));
    await tester.pump();
    expect(engine.chain, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
    expect(cues.events, hasLength(cuesBeforeRefusal));

    await gesture.moveTo(const Offset(0, 0));
    await tester.pump();
    expect(engine.chain, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
    expect(cues.events, hasLength(cuesBeforeRefusal));
    await gesture.up();
  });

  testPlay('retracting the seed clears the chain without a resolve', (
    tester,
  ) async {
    final engine = placed(fill: 4, tiles: {Cell(1, 1): 2, Cell(2, 1): 2});
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues);

    await dragChain(tester, const [Cell(1, 1), Cell(2, 1), Cell(1, 1)]);
    await tester.pump();

    expect(engine.chain, isEmpty);
    expect(engine.score, 0);
    expect(cues.events, [const Cue.step(62, tone: true)]);
    expect(numeral(tester, const Cell(1, 1)), '2');
    expect(numeral(tester, const Cell(2, 1)), '2');
    expect(find.byKey(const ValueKey('chain-connector')), findsNothing);
  });

  testPlay('an empty cell refuses the step', (tester) async {
    final engine = placed(
      fill: 4,
      tiles: {Cell(1, 1): 2, Cell(2, 1): 2},
      holes: {Cell(3, 1)},
    );
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues);

    final gesture = await holdChain(tester, const [Cell(1, 1), Cell(2, 1)]);
    await gesture.moveTo(centerOf(tester, const Cell(3, 1)));
    await tester.pump();

    expect(engine.chain, const [Cell(1, 1), Cell(2, 1)]);
    expect(cues.events, [const Cue.step(62, tone: true)]);
    await gesture.up();
  });

  testPlay(
    'lifting resolves, the score counts the raw sum, then the board settles',
    (tester) async {
      final engine = placed(fill: 2, script: List.filled(40, 2));
      final cues = CueRecorder();
      await pumpPlay(tester, engine: engine, cues: cues);

      await dragChain(tester, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(numeral(tester, const Cell(3, 1)), '8');
      final moving = int.parse(scoreFigure(tester));
      expect(moving, greaterThan(0));
      expect(moving, lessThan(6));
      expect(cues.events.last, const Cue.resolve(64, tone: true));
      expect(cues.events.where((cue) => cue.kind == CueKind.clear), isEmpty);

      await finishBeats(tester);

      expect(scoreFigure(tester), '6');
      expect(engine.score, 6);
      expectBoard(tester, engine);
      expect(cues.events.where((cue) => cue.kind == CueKind.clear), isEmpty);
      expect(cues.events.where((cue) => cue.kind == CueKind.refresh), isEmpty);
    },
  );

  testPlay('a clear of several values is one cue and swaps the supply', (
    tester,
  ) async {
    final engine = placed(
      fill: 8,
      tiles: {Cell(1, 1): 1024, Cell(2, 1): 1024, Cell(3, 1): 2, Cell(4, 1): 4},
      script: List.filled(40, 8),
    );
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues);

    await dragChain(tester, const [Cell(1, 1), Cell(2, 1)]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(supplyLabel(tester), '2, 4, 8');

    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
    expect(supplyLabel(tester), '8, 16, 32');
    expect(cues.events.where((cue) => cue.kind == CueKind.clear), [
      const Cue.clear(tone: true),
    ]);

    await finishBeats(tester);
    expectBoard(tester, engine);
    expect(scoreFigure(tester), '2,048');
  });

  testPlay('a pairless board refreshes once and the score stays the raw sum', (
    tester,
  ) async {
    final engine = ResolveEngine(
      script: [8, ...List.filled(39, 2), ...List.filled(39, 4)],
    );
    engine.place(_strictHighest());
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues);

    await dragChain(tester, const [Cell(1, 1), Cell(2, 1)]);
    await finishBeats(tester);

    expect(scoreFigure(tester), '4');
    expect(engine.score, 4);
    expect(cues.events.where((cue) => cue.kind == CueKind.refresh), [
      const Cue.refresh(tone: true),
    ]);
    expectBoard(tester, engine);
  });

  testPlay('the finger waits until the beats finish', (tester) async {
    final engine = placed(fill: 2, script: List.filled(40, 2));
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues);

    await dragChain(tester, const [Cell(1, 1), Cell(2, 1)]);
    await tester.pump();
    final during = cues.events.length;
    await dragChain(tester, const [Cell(4, 4), Cell(5, 5)]);
    expect(cues.events, hasLength(during));
    expect(engine.chain, isEmpty);

    await finishBeats(tester);
    await dragChain(tester, const [Cell(4, 4), Cell(5, 5)], up: false);
    expect(engine.chain, const [Cell(4, 4), Cell(5, 5)]);
  });

  testPlay('reduced motion fades in place and still plays the resolve', (
    tester,
  ) async {
    final engine = placed(fill: 4, tiles: {Cell(1, 1): 2, Cell(2, 1): 2});
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues, reduceMotion: true);
    final start = tester.getCenter(find.byKey(const ValueKey(Cell(1, 1))));

    await dragChain(tester, const [Cell(1, 1), Cell(2, 1)]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final during = tester.getCenter(find.byKey(const ValueKey(Cell(1, 1))));
    expect((during - start).distance, lessThan(2));
    expect(cues.events.last, const Cue.resolve(62, tone: true));
    expect(numeral(tester, const Cell(2, 1)), '4');
  });

  testPlay('a traveling tile moves toward the head', (tester) async {
    final engine = placed(fill: 4, tiles: {Cell(1, 1): 2, Cell(2, 1): 2});
    await pumpPlay(tester, engine: engine);
    final start = tester.getCenter(find.byKey(const ValueKey(Cell(1, 1))));
    final head = tester.getCenter(find.byKey(const ValueKey(Cell(2, 1))));

    await dragChain(tester, const [Cell(1, 1), Cell(2, 1)]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final during = tester.getCenter(find.byKey(const ValueKey(Cell(1, 1))));
    expect((during - start).distance, greaterThan(8));
    expect((during - head).distance, lessThan((start - head).distance));
  });

  testPlay('mute silences tones, keeps haptics, and is remembered', (
    tester,
  ) async {
    final sound = SoundMemory();
    final engine = placed(fill: 2);
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues, sound: sound);

    final gesture = await holdChain(tester, const [Cell(1, 1), Cell(2, 1)]);
    expect(cues.events.single.tone, isTrue);
    await tester.tap(find.byTooltip('Mute'));
    await tester.pump();
    await gesture.moveTo(centerOf(tester, const Cell(3, 1)));
    await tester.pump();

    expect(cues.events.last.tone, isFalse);
    expect(cues.events.last.haptic, isTrue);
    expect(find.byTooltip('Unmute'), findsOneWidget);
    await gesture.up();
    await finishBeats(tester);

    final again = CueRecorder();
    await pumpPlay(tester, engine: placed(fill: 2), cues: again, sound: sound);
    expect(find.byTooltip('Unmute'), findsOneWidget);
    final next = await holdChain(tester, const [Cell(1, 1), Cell(2, 1)]);
    expect(again.events.single, const Cue.step(62, tone: false));
    expect(again.events.single.haptic, isTrue);
    await next.up();
  });

  testPlay('mute during a beat silences the later cue', (tester) async {
    final engine = placed(
      fill: 8,
      tiles: {Cell(1, 1): 1024, Cell(2, 1): 1024, Cell(3, 1): 2},
      script: List.filled(40, 8),
    );
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues);

    await dragChain(tester, const [Cell(1, 1), Cell(2, 1)]);
    await tester.pump();
    await tester.tap(find.byTooltip('Mute'));
    await tester.pump();
    await finishBeats(tester);

    expect(
      cues.events.where((cue) => cue.kind == CueKind.resolve).single.tone,
      isTrue,
    );
    expect(
      cues.events.where((cue) => cue.kind == CueKind.clear).single.tone,
      isFalse,
    );
    expect(
      cues.events.where((cue) => cue.kind == CueKind.clear).single.haptic,
      isTrue,
    );
  });

  testPlay('a drag from a saved head continues the chain', (tester) async {
    final store = RunStore();
    final playing = placed(
      fill: 4,
      tiles: {Cell(1, 1): 2, Cell(2, 1): 2, Cell(3, 1): 8},
    );
    playing.seed(const Cell(1, 1), const Cell(2, 1));
    store.save(playing);
    final returned = ResolveEngine();
    final cues = CueRecorder();
    await pumpPlay(tester, engine: returned, store: store, cues: cues);

    final gesture = await holdChain(tester, const [Cell(2, 1), Cell(3, 1)]);

    expect(returned.chain, const [Cell(1, 1), Cell(2, 1), Cell(3, 1)]);
    expect(numeral(tester, const Cell(3, 1)), '16');
    expect(cues.events.single, const Cue.step(67, tone: true));
    await gesture.up();
  });

  testPlay('coming back shows the saved chain, and a new seed replaces it', (
    tester,
  ) async {
    final store = RunStore();
    final playing = placed(
      fill: 4,
      tiles: {Cell(1, 1): 2, Cell(2, 1): 2, Cell(4, 4): 8, Cell(5, 5): 8},
    );
    playing.seed(const Cell(1, 1), const Cell(2, 1));
    store.save(playing);
    final cues = CueRecorder();
    final returned = ResolveEngine();
    await pumpPlay(tester, engine: returned, store: store, cues: cues);

    expect(numeral(tester, const Cell(2, 1)), '4');
    expect(find.bySemanticsLabel('2, in the chain'), findsOneWidget);

    final gesture = await holdChain(tester, const [Cell(4, 4), Cell(5, 5)]);
    expect(returned.chain, const [Cell(4, 4), Cell(5, 5)]);
    expect(returned.score, 0);
    expect(cues.events.where((cue) => cue.kind == CueKind.resolve), isEmpty);
    expect(numeral(tester, const Cell(1, 1)), '2');
    expect(numeral(tester, const Cell(5, 5)), '16');
    await gesture.cancel();
  });

  testPlay('a tap on a saved head resolves it', (tester) async {
    final store = RunStore();
    final playing = placed(fill: 4, tiles: {Cell(1, 1): 2, Cell(2, 1): 2});
    playing.seed(const Cell(1, 1), const Cell(2, 1));
    store.save(playing);
    final returned = ResolveEngine(script: List.filled(40, 4));
    final cues = CueRecorder();
    await pumpPlay(tester, engine: returned, store: store, cues: cues);

    await tester.tap(find.byKey(const ValueKey(Cell(2, 1))));
    await finishBeats(tester);

    expect(returned.score, 4);
    expect(returned.chain, isEmpty);
    expect(cues.events.single.kind, CueKind.resolve);
    expectBoard(tester, returned);

    final later = ResolveEngine();
    expect(store.load(later), isTrue);
    expect(later.score, 4);
    expect(later.chain, isEmpty);
  });

  testPlay('abandon waits, names the score, and can be dismissed', (
    tester,
  ) async {
    final engine = placed(
      fill: 8,
      script: List.filled(40, 64),
      tiles: {
        Cell(1, 1): 16,
        Cell(2, 1): 16,
        Cell(3, 1): 64,
        Cell(4, 1): 128,
        Cell(5, 1): 512,
        Cell(5, 2): 1024,
        Cell(4, 2): 2048,
        Cell(3, 2): 8192,
      },
    );
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues);

    await dragChain(tester, const [
      Cell(1, 1),
      Cell(2, 1),
      Cell(3, 1),
      Cell(4, 1),
      Cell(5, 1),
      Cell(5, 2),
      Cell(4, 2),
      Cell(3, 2),
    ]);
    await tester.tap(find.byKey(const ValueKey('abandon')));
    await tester.pump();
    expect(find.text('Abandon this run?'), findsNothing);

    await finishBeats(tester);
    expect(find.text('Abandon this run?'), findsOneWidget);
    expect(find.text('The score of 12,000 will be discarded.'), findsOneWidget);
    expect(scoreFigure(tester), '12,000');

    await tester.tap(find.text('Keep playing'));
    await tester.pumpAndSettle();
    expect(find.text('Abandon this run?'), findsNothing);
    expect(engine.score, 12000);
    expect(scoreFigure(tester), '12,000');

    await tester.tap(find.byKey(const ValueKey('abandon')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('Abandon this run?'), findsNothing);
    expect(engine.score, 12000);
  });

  testPlay('back dismisses abandon and otherwise leaves the run open', (
    tester,
  ) async {
    var left = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') left = true;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final engine = placed(fill: 2);
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, cues: cues);

    await tester.tap(find.byKey(const ValueKey('abandon')));
    await tester.pumpAndSettle();
    expect(find.text('Abandon this run?'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Abandon this run?'), findsNothing);
    expect(engine.chain, const [Cell(1, 1), Cell(2, 1)]);
    expect(engine.score, 0);
    expect(left, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(engine.chain, const [Cell(1, 1), Cell(2, 1)]);
    expect(engine.score, 0);
    expect(left, isTrue);
    expect(cues.events, isEmpty);
  });

  testPlay('confirming abandon deals a new run with one haptic', (
    tester,
  ) async {
    final store = RunStore();
    final engine = placed(fill: 8, tiles: {Cell(1, 1): 512, Cell(2, 1): 512});
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    engine.resolve();
    final cues = CueRecorder();
    await pumpPlay(tester, engine: engine, store: store, cues: cues);
    expect(scoreFigure(tester), '1,024');

    await tester.tap(find.byKey(const ValueKey('abandon')));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      centerOf(tester, const Cell(1, 8)),
    );
    await gesture.moveTo(centerOf(tester, const Cell(2, 8)));
    await gesture.up();
    await tester.pump();
    expect(cues.events, isEmpty);
    expect(engine.score, 1024);

    await tester.tap(find.widgetWithText(FilledButton, 'Abandon'));
    await tester.pumpAndSettle();

    expect(engine.score, 0);
    expect(engine.chain, isEmpty);
    expect(engine.cleared, isEmpty);
    expect(scoreFigure(tester), '0');
    expect(supplyLabel(tester), '2, 4, 8');
    expect(find.text('1024'), findsNothing);
    expect(cues.events, [const Cue.abandon()]);
    for (var row = 1; row <= 8; row++) {
      for (var column = 1; column <= 5; column++) {
        expect(numeral(tester, Cell(column, row)), isIn(['2', '4', '8']));
      }
    }

    final later = ResolveEngine();
    expect(store.load(later), isTrue);
    expect(later.score, 0);
    expect(later.chain, isEmpty);
  });

  testPlay('the portrait column stays within 420 and the header is one row', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpPlay(tester, engine: placed(fill: 2));

    final column = tester.getRect(find.byKey(const ValueKey('play-column')));
    expect(column.width, lessThanOrEqualTo(420));
    expect(column.left, greaterThan(100));
    expect(column.right, lessThan(700));

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pump();
    final wordmark = tester.getTopLeft(find.text('2248'));
    final score = tester.getTopLeft(find.byKey(const ValueKey('score')));
    expect((wordmark.dy - score.dy).abs(), lessThan(24));
    expect(wordmark.dx, lessThan(score.dx));
  });

  testPlay('dialog text follows the text scale and tile numerals do not', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final engine = placed(fill: 2);
    engine.seed(const Cell(1, 1), const Cell(2, 1));
    await pumpPlay(tester, engine: engine);

    final tile = tester.element(
      find.descendant(
        of: find.byKey(const ValueKey(Cell(1, 1))),
        matching: find.byType(Text),
      ),
    );
    expect(MediaQuery.textScalerOf(tile).scale(10), 10);

    await tester.tap(find.byKey(const ValueKey('abandon')));
    await tester.pumpAndSettle();
    final title = tester.element(find.text('Abandon this run?'));
    expect(MediaQuery.textScalerOf(title).scale(10), 20);
    final body = tester.element(find.text('The score of 0 will be discarded.'));
    expect(MediaQuery.textScalerOf(body).scale(10), 20);
  });

  testPlay('the score and the supply are spoken as their figures', (
    tester,
  ) async {
    final engine = placed(fill: 2, script: List.filled(40, 2));
    await pumpPlay(tester, engine: engine);
    expect(find.bySemanticsLabel('0'), findsOneWidget);
    expect(supplyLabel(tester), '2, 4, 8');

    await dragChain(tester, const [
      Cell(1, 1),
      Cell(2, 1),
      Cell(3, 1),
      Cell(4, 1),
      Cell(5, 1),
    ]);
    await finishBeats(tester);
    expect(find.bySemanticsLabel('10'), findsOneWidget);
  });
}

Future<void> pumpPlay(
  WidgetTester tester, {
  required ResolveEngine engine,
  RunStore? store,
  CueRecorder? cues,
  SoundMemory? sound,
  bool reduceMotion = false,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(
        disableAnimations: reduceMotion,
        reduceMotion: reduceMotion,
      );
  addTearDown(() {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
  });
  await tester.pumpWidget(
    MyApp(
      engine: engine,
      store: store ?? RunStore(),
      cues: cues ?? CueRecorder(),
      sound: sound ?? SoundMemory(),
    ),
  );
  await tester.pump();
}

ResolveEngine placed({
  int? fill,
  Map<Cell, int> tiles = const {},
  Set<Cell> holes = const {},
  List<int> script = const [],
}) {
  final engine = ResolveEngine(script: script);
  engine.place([
    for (var row = 1; row <= 8; row++)
      for (var column = 1; column <= 5; column++)
        if (!holes.contains(Cell(column, row)) &&
            (fill != null || tiles.containsKey(Cell(column, row))))
          Placement(column, row, tiles[Cell(column, row)] ?? fill!),
  ]);
  return engine;
}

Future<TestGesture> holdChain(
  WidgetTester tester,
  List<Cell> cells, {
  PointerDeviceKind kind = PointerDeviceKind.touch,
}) async {
  final gesture = await tester.startGesture(
    centerOf(tester, cells.first),
    kind: kind,
  );
  for (final cell in cells.skip(1)) {
    await gesture.moveTo(centerOf(tester, cell));
    await tester.pump();
  }
  return gesture;
}

Future<void> dragChain(
  WidgetTester tester,
  List<Cell> cells, {
  bool up = true,
  PointerDeviceKind kind = PointerDeviceKind.touch,
}) async {
  final gesture = await holdChain(tester, cells, kind: kind);
  if (up) {
    await gesture.up();
    await tester.pump();
  }
}

Future<void> finishBeats(WidgetTester tester) async {
  for (var beat = 0; beat < 6; beat++) {
    await tester.pump(boardBeat);
  }
  await tester.pump();
}

void expectBoard(WidgetTester tester, ResolveEngine engine) {
  for (var row = 1; row <= 8; row++) {
    for (var column = 1; column <= 5; column++) {
      expect(
        numeral(tester, Cell(column, row)),
        engine.tileAt(Cell(column, row))?.toString(),
        reason: 'column $column, row $row',
      );
    }
  }
}

String? numeral(WidgetTester tester, Cell cell) {
  final finder = find.descendant(
    of: find.byKey(ValueKey(cell)),
    matching: find.byType(Text),
  );
  if (finder.evaluate().isEmpty) return null;
  return tester.widget<Text>(finder).data;
}

Color tileColorOf(WidgetTester tester, Cell cell) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byKey(ValueKey(cell)),
      matching: find.byType(DecoratedBox),
    ),
  );
  return (box.decoration as BoxDecoration).color!;
}

Color numeralColor(WidgetTester tester, Cell cell) {
  return tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(ValueKey(cell)),
          matching: find.byType(Text),
        ),
      )
      .style!
      .color!;
}

double rimWidth(WidgetTester tester, Cell cell) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byKey(ValueKey(cell)),
      matching: find.byType(DecoratedBox),
    ),
  );
  final border = (box.decoration as BoxDecoration).border! as Border;
  return border.top.width;
}

Color wellColor(WidgetTester tester, int column, int row) {
  final box = tester.widget<DecoratedBox>(
    find.byKey(ValueKey('well-$column-$row')),
  );
  return (box.decoration as BoxDecoration).color!;
}

String scoreFigure(WidgetTester tester) {
  return tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('score')),
          matching: find.byType(Text),
        ),
      )
      .data!;
}

String supplyLabel(WidgetTester tester) {
  return tester.getSemantics(find.byKey(const ValueKey('supply'))).label;
}

Offset centerOf(WidgetTester tester, Cell cell) {
  final tile = find.byKey(ValueKey(cell));
  if (tile.evaluate().isNotEmpty) return tester.getCenter(tile);
  return tester.getCenter(
    find.byKey(ValueKey('well-${cell.column}-${cell.row}')),
  );
}

bool _neighborMatches(WidgetTester tester, int column, int row, String text) {
  for (var otherRow = row; otherRow <= 8; otherRow++) {
    for (var otherColumn = 1; otherColumn <= 5; otherColumn++) {
      if (otherRow == row && otherColumn <= column) continue;
      if ((column - otherColumn).abs() > 1 || (row - otherRow).abs() > 1) {
        continue;
      }
      if (numeral(tester, Cell(otherColumn, otherRow)) == text) return true;
    }
  }
  return false;
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
