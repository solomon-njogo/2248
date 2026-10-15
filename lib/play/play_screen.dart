import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:game_2248/cues/cues.dart';
import 'package:game_2248/resolve/resolve_engine.dart';
import 'package:game_2248/run/sound_memory.dart';
import 'package:game_2248/theme/app_colors.dart';
import 'package:game_2248/theme/app_text_styles.dart';

const boardBeat = Duration(milliseconds: 200);

class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    required this.engine,
    required this.store,
    required this.cues,
    required this.sound,
  });

  final ResolveEngine engine;
  final RunStore store;
  final Cues cues;
  final SoundMemory sound;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

enum _Phase { idle, resolve, clear, fall, refill, refresh }

class _TileView {
  const _TileView({
    required this.identity,
    required this.tile,
    required this.column,
    required this.row,
    required this.spoken,
    this.opacity = 1,
    this.scale = 1,
    this.inChain = false,
    this.head = false,
  });

  final Key identity;
  final int tile;
  final double column;
  final double row;
  final String spoken;
  final double opacity;
  final double scale;
  final bool inChain;
  final bool head;
}

class _Grid {
  _Grid(this.cell);

  static const gap = 8.0;

  final double cell;

  double get width => cell * 5 + gap * 4;

  double get height => cell * 8 + gap * 7;

  static _Grid fit(double maxWidth, double maxHeight) {
    final byWidth = (maxWidth - gap * 4) / 5;
    final byHeight = (maxHeight - gap * 7) / 8;
    final cell = math.min(byWidth, byHeight);
    return _Grid(cell.isFinite && cell > 0 ? cell : 1);
  }

  Cell? cellAt(Offset local) {
    final column = _axis(local.dx, 5);
    final row = _axis(local.dy, 8);
    if (column == null || row == null) return null;
    return Cell(column, row);
  }

  int? _axis(double position, int count) {
    if (position < 0) return null;
    final stride = cell + gap;
    final index = (position / stride).floor();
    if (index < 0 || index >= count) return null;
    if (position - index * stride > cell) return null;
    return index + 1;
  }
}

class _PlayScreenState extends State<PlayScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  _Grid? _grid;
  _Phase _phase = _Phase.idle;
  ResolveReport? _report;
  Map<Cell, int> _before = {};
  int _scoreFrom = 0;
  List<int> _supplyBefore = const [2, 4, 8];
  var _busy = false;
  var _dialogOpen = false;
  var _abandonWhenSettled = false;
  var _reduceMotion = false;

  int? _pointer;
  Cell? _anchor;
  var _moved = false;
  var _gestureDraws = false;
  Duration? _downAt;

  @override
  void initState() {
    super.initState();
    // A controller finishes only after elapsed time passes its duration,
    // so this is a millisecond under the 200ms beat the screen plays.
    _motion =
        AnimationController(
          vsync: this,
          duration: boardBeat - const Duration(milliseconds: 1),
        )..addListener(() {
          if (mounted) setState(() {});
        });
    final loaded = widget.store.load(widget.engine);
    if (!loaded && _untouched(widget.engine)) {
      widget.engine.deal();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  bool _untouched(ResolveEngine engine) {
    if (engine.score != 0 ||
        engine.chain.isNotEmpty ||
        engine.cleared.isNotEmpty) {
      return false;
    }
    for (var row = 1; row <= 8; row++) {
      for (var column = 1; column <= 5; column++) {
        if (engine.tileAt(Cell(column, row)) != null) return false;
      }
    }
    return true;
  }

  double get _eased => Curves.easeOut.transform(_motion.value.clamp(0, 1));

  void _down(PointerDownEvent event) {
    if (_pointer != null || _busy || _dialogOpen) return;
    final cell = _grid?.cellAt(event.localPosition);
    _pointer = event.pointer;
    _anchor = cell;
    _moved = false;
    _gestureDraws = false;
    _downAt = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    SchedulerBinding.instance.scheduleFrame();
    final chain = widget.engine.chain;
    if (cell != null && chain.isNotEmpty && cell == chain.last) {
      _gestureDraws = true;
    }
  }

  void _move(PointerMoveEvent event) {
    if (event.pointer != _pointer || _busy || _dialogOpen) return;
    final cell = _grid?.cellAt(event.localPosition);
    if (cell == null || cell == _anchor && !_moved && !_gestureDraws) return;
    _moved = true;
    final engine = widget.engine;
    if (!_gestureDraws) {
      final start = _anchor;
      if (start != null && engine.seed(start, cell)) {
        _gestureDraws = true;
        _confirmChain();
      }
      return;
    }
    if (engine.step(cell)) _confirmChain();
  }

  void _up(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    if (_busy || _dialogOpen) return;
    final held = _downAt == null
        ? Duration.zero
        : SchedulerBinding.instance.currentSystemFrameTimeStamp - _downAt!;
    final chain = widget.engine.chain;
    final head = chain.isEmpty ? null : chain.last;
    final tappedHead = !_moved && _anchor != null && _anchor == head;
    if (!_moved && held >= const Duration(milliseconds: 500)) return;
    if (_gestureDraws && chain.isNotEmpty) {
      _resolve();
    } else if (tappedHead) {
      _resolve();
    }
  }

  void _cancel(PointerCancelEvent event) {
    if (event.pointer == _pointer) _pointer = null;
  }

  void _confirmChain() {
    final pending = widget.engine.pendingResult;
    if (pending != null) {
      widget.cues.play(Cue.step(pitchOf(pending), tone: !widget.sound.muted));
    }
    widget.store.save(widget.engine);
    setState(() {});
  }

  Future<void> _resolve() async {
    if (_busy || widget.engine.chain.isEmpty) return;
    final engine = widget.engine;
    final pending = engine.pendingResult;
    if (pending == null) return;
    final before = <Cell, int>{
      for (var row = 1; row <= 8; row++)
        for (var column = 1; column <= 5; column++)
          Cell(column, row): ?engine.tileAt(Cell(column, row)),
    };
    final supplyBefore = List<int>.of(engine.supply);
    final scoreFrom = engine.score;
    final report = engine.resolve();
    if (report == null) return;
    widget.store.save(engine);
    widget.cues.play(Cue.resolve(pitchOf(pending), tone: !widget.sound.muted));
    setState(() {
      _busy = true;
      _before = before;
      _supplyBefore = supplyBefore;
      _scoreFrom = scoreFrom;
      _report = report;
      _phase = _Phase.resolve;
    });
    await _motion.forward(from: 0);
    if (!mounted) return;
    if (report.leaving.isNotEmpty) {
      widget.cues.play(Cue.clear(tone: !widget.sound.muted));
      setState(() => _phase = _Phase.clear);
      await _motion.forward(from: 0);
      if (!mounted) return;
    }
    if (report.falls.isNotEmpty) {
      setState(() => _phase = _Phase.fall);
      await _motion.forward(from: 0);
      if (!mounted) return;
    }
    if (report.refilled.isNotEmpty) {
      setState(() => _phase = _Phase.refill);
      await _motion.forward(from: 0);
      if (!mounted) return;
    }
    if (report.refreshed != null) {
      widget.cues.play(Cue.refresh(tone: !widget.sound.muted));
      setState(() => _phase = _Phase.refresh);
      await _motion.forward(from: 0);
      if (!mounted) return;
    }
    setState(() {
      _phase = _Phase.idle;
      _busy = false;
      _report = null;
    });
    if (_abandonWhenSettled) {
      _abandonWhenSettled = false;
      await _openAbandon();
    }
  }

  Future<void> _openAbandon() async {
    if (_dialogOpen || !mounted) return;
    final score = MaterialLocalizations.of(
      context,
    ).formatDecimal(widget.engine.score);
    setState(() => _dialogOpen = true);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: const Text('Abandon this run?'),
          content: Text('The score of $score will be discarded.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep playing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Abandon'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    setState(() => _dialogOpen = false);
    if (confirmed == true) {
      widget.engine.abandon();
      widget.store.save(widget.engine);
      widget.cues.play(const Cue.abandon());
      setState(() {});
    }
  }

  void _pressAbandon() {
    if (_busy) {
      _abandonWhenSettled = true;
      return;
    }
    _openAbandon();
  }

  void _toggleMute() {
    widget.sound.setMuted(!widget.sound.muted);
    setState(() {});
  }

  int _shownScore() {
    final report = _report;
    if (_phase != _Phase.resolve || report == null) return widget.engine.score;
    return _scoreFrom + (report.rawSum * _eased).round();
  }

  List<int> _shownSupply() {
    if (_phase == _Phase.resolve) return _supplyBefore;
    return widget.engine.supply;
  }

  List<_TileView> _views() {
    final report = _report;
    if (_phase == _Phase.idle || report == null) return _idleViews();
    final t = _eased;
    switch (_phase) {
      case _Phase.resolve:
        return _resolveViews(report, t);
      case _Phase.clear:
        return _placedViews(
          _afterResolve(report),
          leaving: report.leaving,
          t: t,
        );
      case _Phase.fall:
        return _fallViews(report, t);
      case _Phase.refill:
        return _refillViews(report, t);
      case _Phase.refresh:
        return _refreshViews(report, t);
      case _Phase.idle:
        return _idleViews();
    }
  }

  List<_TileView> _idleViews() {
    final engine = widget.engine;
    final chain = engine.chain;
    final pending = engine.pendingResult;
    final views = <_TileView>[];
    for (var row = 1; row <= 8; row++) {
      for (var column = 1; column <= 5; column++) {
        final cell = Cell(column, row);
        final tile = engine.tileAt(cell);
        if (tile == null) continue;
        final head = chain.isNotEmpty && cell == chain.last;
        final inChain = chain.contains(cell);
        final shown = head ? pending! : tile;
        views.add(
          _TileView(
            identity: ValueKey(cell),
            tile: shown,
            column: column.toDouble(),
            row: row.toDouble(),
            spoken: head
                ? '$shown'
                : inChain
                ? '$tile, in the chain'
                : '$tile',
            inChain: inChain,
            head: head,
          ),
        );
      }
    }
    return views;
  }

  List<_TileView> _resolveViews(ResolveReport report, double t) {
    final views = <_TileView>[];
    for (final entry in _before.entries) {
      final cell = entry.key;
      final gathered = report.gathered.contains(cell);
      final head = cell == report.head;
      if (gathered) {
        final column = _reduceMotion
            ? cell.column.toDouble()
            : _lerp(cell.column, report.head.column, t);
        final row = _reduceMotion
            ? cell.row.toDouble()
            : _lerp(cell.row, report.head.row, t);
        views.add(
          _TileView(
            identity: ValueKey(cell),
            tile: entry.value,
            column: column,
            row: row,
            spoken: '${entry.value}, in the chain',
            opacity: _reduceMotion ? 1 - t : 1,
            scale: _reduceMotion ? 1 : 1 - (0.7 * t),
            inChain: true,
          ),
        );
      } else if (head) {
        views.add(
          _TileView(
            identity: ValueKey(cell),
            tile: report.result,
            column: cell.column.toDouble(),
            row: cell.row.toDouble(),
            spoken: '${report.result}',
            inChain: true,
            head: true,
          ),
        );
      } else {
        views.add(_still(cell, entry.value));
      }
    }
    return views;
  }

  List<_TileView> _placedViews(
    Map<Cell, int> board, {
    List<ClearedTile> leaving = const [],
    required double t,
  }) {
    return [
      for (final entry in board.entries)
        if (leaving.any((tile) => tile.cell == entry.key))
          _still(
            entry.key,
            entry.value,
            opacity: _reduceMotion ? 1 - t : 1,
            scale: _reduceMotion ? 1 : 1 - t,
          )
        else
          _still(entry.key, entry.value),
    ];
  }

  List<_TileView> _fallViews(ResolveReport report, double t) {
    final board = _afterClear(report);
    final falls = {for (final fall in report.falls) fall.from: fall};
    final views = <_TileView>[];
    for (final entry in board.entries) {
      final fall = falls[entry.key];
      if (fall == null) {
        views.add(_still(entry.key, entry.value));
        continue;
      }
      if (_reduceMotion) {
        views.add(_still(entry.key, entry.value, opacity: 1 - t));
        views.add(
          _still(
            fall.to,
            fall.tile,
            opacity: t,
            identity: ValueKey('arrive-${fall.to.column}-${fall.to.row}'),
          ),
        );
      } else {
        views.add(
          _TileView(
            identity: ValueKey(entry.key),
            tile: entry.value,
            column: _lerp(fall.from.column, fall.to.column, t),
            row: _lerp(fall.from.row, fall.to.row, t),
            spoken: '${entry.value}',
          ),
        );
      }
    }
    return views;
  }

  List<_TileView> _refillViews(ResolveReport report, double t) {
    final views = [
      for (final entry in _afterFall(report).entries)
        _still(entry.key, entry.value),
    ];
    for (final refill in report.refilled) {
      views.add(
        _TileView(
          identity: ValueKey(refill.cell),
          tile: refill.tile,
          column: refill.cell.column.toDouble(),
          row: _reduceMotion
              ? refill.cell.row.toDouble()
              : _lerp(0, refill.cell.row, t),
          spoken: '${refill.tile}',
          opacity: _reduceMotion ? t : 1,
        ),
      );
    }
    return views;
  }

  List<_TileView> _refreshViews(ResolveReport report, double t) {
    final views = <_TileView>[];
    for (final entry in _afterRefill(report).entries) {
      views.add(
        _still(
          entry.key,
          entry.value,
          opacity: 1 - t,
          identity: ValueKey('was-${entry.key.column}-${entry.key.row}'),
        ),
      );
    }
    for (final placement in report.refreshed!) {
      final tile = placement.tile;
      if (tile == null) continue;
      final cell = Cell(placement.column, placement.row);
      views.add(_still(cell, tile, opacity: t));
    }
    return views;
  }

  _TileView _still(
    Cell cell,
    int tile, {
    double opacity = 1,
    double scale = 1,
    Key? identity,
  }) {
    return _TileView(
      identity: identity ?? ValueKey(cell),
      tile: tile,
      column: cell.column.toDouble(),
      row: cell.row.toDouble(),
      spoken: '$tile',
      opacity: opacity,
      scale: scale,
    );
  }

  Map<Cell, int> _afterResolve(ResolveReport report) {
    final next = Map<Cell, int>.of(_before);
    for (final cell in report.gathered) {
      next.remove(cell);
    }
    next[report.head] = report.result;
    return next;
  }

  Map<Cell, int> _afterClear(ResolveReport report) {
    final next = _afterResolve(report);
    for (final leaving in report.leaving) {
      next.remove(leaving.cell);
    }
    return next;
  }

  Map<Cell, int> _afterFall(ResolveReport report) {
    final next = _afterClear(report);
    for (final fall in report.falls) {
      next.remove(fall.from);
    }
    for (final fall in report.falls) {
      next[fall.to] = fall.tile;
    }
    return next;
  }

  Map<Cell, int> _afterRefill(ResolveReport report) {
    final next = _afterFall(report);
    for (final refill in report.refilled) {
      next[refill.cell] = refill.tile;
    }
    return next;
  }

  double _lerp(num from, num to, double t) => from + (to - from) * t;

  @override
  Widget build(BuildContext context) {
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    final score = MaterialLocalizations.of(
      context,
    ).formatDecimal(_shownScore());
    final supply = _shownSupply();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.night,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              key: const ValueKey('play-column'),
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _header(score),
                    const SizedBox(height: 20),
                    _supply(supply),
                    const SizedBox(height: 20),
                    Expanded(child: _board()),
                    const SizedBox(height: 20),
                    _controls(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(String score) {
    return Row(
      children: [
        const Text('2248', style: AppTextStyles.wordmark),
        const Spacer(),
        Flexible(
          child: Semantics(
            key: const ValueKey('score'),
            container: true,
            label: score,
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.chip,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(score, style: AppTextStyles.score),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _supply(List<int> supply) {
    return Semantics(
      key: const ValueKey('supply'),
      container: true,
      label: supply.join(', '),
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.chip,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gaps = 8.0 * (supply.length - 1);
                final size = math.min(
                  48.0,
                  (constraints.maxWidth - gaps) / supply.length,
                );
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < supply.length; index++) ...[
                      if (index > 0) const SizedBox(width: 8),
                      _face(supply[index], size, inChain: false),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _controls() {
    final muted = widget.sound.muted;
    return Row(
      children: [
        TextButton(
          key: const ValueKey('abandon'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.mist,
            minimumSize: const Size(48, 48),
            textStyle: AppTextStyles.label,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _pressAbandon,
          child: const Text('ABANDON'),
        ),
        const Spacer(),
        IconButton(
          key: const ValueKey('mute'),
          tooltip: muted ? 'Unmute' : 'Mute',
          color: const Color(0xffffffff),
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: _toggleMute,
          icon: Icon(
            muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          ),
        ),
      ],
    );
  }

  Widget _board() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final grid = _Grid.fit(constraints.maxWidth, constraints.maxHeight);
        _grid = grid;
        final views = _views();
        final chain = widget.engine.chain;
        final showConnector = _phase == _Phase.idle && chain.length >= 2;
        return Center(
          child: SizedBox(
            width: grid.width,
            height: grid.height,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _down,
              onPointerMove: _move,
              onPointerUp: _up,
              onPointerCancel: _cancel,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var row = 1; row <= 8; row++)
                    for (var column = 1; column <= 5; column++)
                      _well(grid, column, row),
                  if (showConnector)
                    ExcludeSemantics(
                      child: CustomPaint(
                        key: const ValueKey('chain-connector'),
                        size: Size(grid.width, grid.height),
                        painter: _ConnectorPainter([
                          for (final cell in chain)
                            _center(
                              grid,
                              cell.column.toDouble(),
                              cell.row.toDouble(),
                            ),
                        ]),
                      ),
                    ),
                  for (final view in views) _tile(grid, view),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _well(_Grid grid, int column, int row) {
    final origin = _origin(grid, column.toDouble(), row.toDouble());
    return Positioned(
      left: origin.dx,
      top: origin.dy,
      width: grid.cell,
      height: grid.cell,
      child: DecoratedBox(
        key: ValueKey('well-$column-$row'),
        decoration: BoxDecoration(
          color: row == 8 ? AppColors.floor : AppColors.well,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _tile(_Grid grid, _TileView view) {
    final origin = _origin(grid, view.column, view.row);
    return Positioned(
      left: origin.dx,
      top: origin.dy,
      width: grid.cell,
      height: grid.cell,
      child: Opacity(
        opacity: view.opacity.clamp(0, 1),
        child: Transform.scale(
          scale: view.scale.clamp(0, 1),
          child: Semantics(
            key: view.identity,
            container: true,
            label: view.spoken,
            child: ExcludeSemantics(
              child: _face(view.tile, grid.cell, inChain: view.inChain),
            ),
          ),
        ),
      ),
    );
  }

  Widget _face(int tile, double size, {required bool inChain}) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tileColor(tile),
          borderRadius: BorderRadius.circular(16),
          border: inChain
              ? Border.all(color: const Color(0xffffffff), width: 6)
              : null,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.noScaling),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$tile',
                  style: AppTextStyles.tile.copyWith(color: numeralColor(tile)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Offset _origin(_Grid grid, double column, double row) {
    final stride = grid.cell + _Grid.gap;
    return Offset((column - 1) * stride, (row - 1) * stride);
  }

  Offset _center(_Grid grid, double column, double row) {
    final origin = _origin(grid, column, row);
    return origin + Offset(grid.cell / 2, grid.cell / 2);
  }
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xffffffff)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) {
    if (oldDelegate.points.length != points.length) return true;
    for (var index = 0; index < points.length; index++) {
      if (oldDelegate.points[index] != points[index]) return true;
    }
    return false;
  }
}
