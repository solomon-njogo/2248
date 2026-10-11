import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../storage/score_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'aether_world.dart';
import 'game_models.dart';
import 'game_painter.dart';
import 'score_format.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _focus = FocusNode();
  final _pressed = <LogicalKeyboardKey>{};
  final _store = ScoreStore();
  late final AetherWorld world = AetherWorld(onNewBest: _saveBest);
  late final Ticker _ticker;

  Duration _last = Duration.zero;
  double _fieldLeft = 0;
  double _fieldWidth = 0;
  double _fieldHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick)..start();
    _loadBest();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0x00000000),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused) &&
        world.phase == RunPhase.playing) {
      world.togglePause();
      if (mounted) setState(() {});
    }
    if (state == AppLifecycleState.resumed) {
      _last = Duration.zero;
    }
  }

  void _onTick(Duration elapsed) {
    var dt = 0.0;
    if (_last != Duration.zero) {
      dt = (elapsed - _last).inMicroseconds / 1000000;
    }
    _last = elapsed;
    if (_fieldWidth > 0 && _fieldHeight > 0 && dt > 0) {
      world.update(dt);
      _pulse(world.consumeFeel());
      if (mounted && world.takeUiTick()) setState(() {});
    }
  }

  Future<void> _loadBest() async {
    try {
      final value = await _store.read();
      if (!mounted) return;
      setState(() {
        if (value > world.best) world.best = value;
      });
    } on Exception {
      // High score stays in memory when preferences are unavailable.
    }
  }

  Future<void> _saveBest(int score) async {
    try {
      await _store.writeIfHigher(score);
    } on Exception {
      // The in-memory best still shows for this session.
    }
  }

  void _pulse(Feel feel) {
    switch (feel) {
      case Feel.collect:
        HapticFeedback.selectionClick().ignore();
      case Feel.shield:
        HapticFeedback.lightImpact().ignore();
      case Feel.hit:
        HapticFeedback.heavyImpact().ignore();
      case Feel.none:
        break;
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final steer = _isSteerKey(key);
    final action = _isActionKey(key);
    if (!steer && !action) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      if (steer) _pressed.add(key);
      if (action) _onAction(key);
    } else if (event is KeyUpEvent) {
      _pressed.remove(key);
    }
    _syncAxis();
    return KeyEventResult.handled;
  }

  void _onAction(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.escape) {
      setState(world.back);
      return;
    }
    if (key == LogicalKeyboardKey.keyP) {
      setState(world.togglePause);
      return;
    }
    switch (world.phase) {
      case RunPhase.menu:
      case RunPhase.gameOver:
        _play();
      case RunPhase.paused:
        setState(world.togglePause);
      case RunPhase.playing:
        _shield();
    }
  }

  void _syncAxis() {
    final left =
        _pressed.contains(LogicalKeyboardKey.arrowLeft) ||
        _pressed.contains(LogicalKeyboardKey.keyA);
    final right =
        _pressed.contains(LogicalKeyboardKey.arrowRight) ||
        _pressed.contains(LogicalKeyboardKey.keyD);
    world.keyboardAxis = (right ? 1 : 0) - (left ? 1 : 0);
  }

  void _capture(BoxConstraints constraints) {
    final maxW = constraints.maxWidth;
    final maxH = constraints.maxHeight;
    final capped = maxW >= 640;
    _fieldWidth = capped ? math.min(420.0, maxW) : maxW;
    _fieldLeft = (maxW - _fieldWidth) / 2;
    _fieldHeight = maxH;
    world.layout(Size(_fieldWidth, _fieldHeight));
  }

  void _point(Offset local, bool active) {
    _focus.requestFocus();
    world.pointerActive = active;
    world.steerTo(local.dx - _fieldLeft);
  }

  void _play() {
    world.start();
    _focus.requestFocus();
    setState(() {});
  }

  void _shield() {
    world.tryShield();
    _pulse(world.consumeFeel());
    setState(() {});
  }

  bool _isSteerKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.keyD;
  }

  bool _isActionKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.keyP;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: world.phase == RunPhase.menu,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(world.back);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: ExcludeFocus(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _capture(constraints);
                final field = Rect.fromLTWH(
                  _fieldLeft,
                  0,
                  _fieldWidth,
                  _fieldHeight,
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    MouseRegion(
                      cursor: world.phase == RunPhase.playing
                          ? SystemMouseCursors.precise
                          : MouseCursor.defer,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanDown: (details) =>
                            _point(details.localPosition, true),
                        onPanUpdate: (details) =>
                            _point(details.localPosition, true),
                        onPanEnd: (_) => world.pointerActive = false,
                        onPanCancel: () => world.pointerActive = false,
                        child: CustomPaint(
                          painter: GamePainter(world: world, field: field),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    if (world.phase == RunPhase.playing ||
                        world.phase == RunPhase.paused)
                      Positioned(
                        left: field.left,
                        width: field.width,
                        top: 0,
                        bottom: 0,
                        child: _Hud(
                          world: world,
                          onPause: () => setState(world.togglePause),
                          onShield: _shield,
                        ),
                      ),
                    if (world.phase == RunPhase.menu) ...[
                      const _MenuBarrier(),
                      _Menu(best: world.best, onPlay: _play),
                    ],
                    if (world.phase == RunPhase.paused)
                      _Scrim(
                        child: _PauseCard(
                          onResume: () => setState(world.togglePause),
                          onMenu: () => setState(world.exitToMenu),
                        ),
                      ),
                    if (world.phase == RunPhase.gameOver)
                      _Scrim(
                        child: _GameOverCard(
                          score: world.score,
                          best: world.best,
                          newBest: world.newBest,
                          onAgain: _play,
                          onMenu: () => setState(world.exitToMenu),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuBarrier extends StatelessWidget {
  const _MenuBarrier();

  @override
  Widget build(BuildContext context) {
    return const ModalBarrier(dismissible: false, color: Color(0x00000000));
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModalBarrier(
          dismissible: false,
          color: AppColors.background.withValues(alpha: 0.72),
        ),
        child,
      ],
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.best, required this.onPlay});

  final int best;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final panelWidth = math.min(420.0, constraints.maxWidth - 32);
          final bottomGap = math.max(96.0, constraints.maxHeight * 0.28);
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomGap),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(
                  0.0,
                  constraints.maxHeight - bottomGap - 24,
                ),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: panelWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: constraints.maxHeight < 560 ? 8 : 28),
                      const Text(
                        'ENDLESS DRIFT',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.eyebrow,
                      ),
                      const SizedBox(height: 12),
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('AETHER', style: AppTextStyles.display),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'DRIFT',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.wordmark,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Slip past the rocks. Catch the light.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            child: Text(
                              best > 0
                                  ? 'Best  ${formatScore(best)}'
                                  : 'No record yet',
                              style: AppTextStyles.label,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        key: const Key('play_button'),
                        onPressed: onPlay,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play'),
                      ),
                      const SizedBox(height: 22),
                      const _Hint(
                        icon: Icons.swipe_rounded,
                        text: 'Drag to steer. Arrow keys or A and D work too.',
                      ),
                      const SizedBox(height: 10),
                      const _Hint(
                        icon: Icons.diamond_rounded,
                        text: 'Thread the gap and pick up the light shards.',
                      ),
                      const SizedBox(height: 10),
                      const _Hint(
                        icon: Icons.bolt_rounded,
                        text: 'Shield blast clears a path. Space fires it.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppTextStyles.hint)),
      ],
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.world,
    required this.onPause,
    required this.onShield,
  });

  final AetherWorld world;
  final VoidCallback onPause;
  final VoidCallback onShield;

  @override
  Widget build(BuildContext context) {
    final beating = world.best > 0 && world.score.floor() > world.best;
    final bestLine = world.best <= 0
        ? 'First run'
        : beating
        ? 'New best'
        : 'Best ${formatScore(world.best)}';
    final ready = world.shieldReady;
    final progress = ready
        ? 1.0
        : (1 - world.shieldCooldown / AetherWorld.shieldCooldownMax)
              .clamp(0.0, 1.0)
              .toDouble();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatScore(world.score),
                          style: AppTextStyles.score,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bestLine,
                        style: AppTextStyles.hint.copyWith(
                          color: beating
                              ? AppColors.accent
                              : AppColors.textMuted,
                        ),
                      ),
                      if (world.combo > 1) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Combo x${world.combo}',
                          style: AppTextStyles.combo,
                        ),
                      ],
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 88,
                        height: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: world.pressure,
                            minHeight: 4,
                            backgroundColor: AppColors.surfaceBorder,
                            color: Color.lerp(
                              AppColors.primary,
                              AppColors.secondary,
                              world.pressure,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Pause',
                  child: IconButton(
                    key: const Key('pause_button'),
                    onPressed: onPause,
                    icon: const Icon(Icons.pause_rounded),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                button: true,
                label: ready ? 'Shield blast' : 'Shield recharging',
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3,
                        strokeCap: StrokeCap.round,
                        color: ready ? AppColors.accent : AppColors.primaryDim,
                        backgroundColor: AppColors.surfaceBorder,
                      ),
                      Material(
                        color: ready ? AppColors.accent : AppColors.surface,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: const Key('shield_button'),
                          customBorder: const CircleBorder(),
                          onTap: onShield,
                          child: SizedBox(
                            width: 58,
                            height: 58,
                            child: Icon(
                              Icons.bolt_rounded,
                              color: ready
                                  ? AppColors.ink
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseCard extends StatelessWidget {
  const _PauseCard({required this.onResume, required this.onMenu});

  final VoidCallback onResume;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      children: [
        const Text(
          'Paused',
          textAlign: TextAlign.center,
          style: AppTextStyles.title,
        ),
        const SizedBox(height: 8),
        const Text(
          'The rift holds still.',
          textAlign: TextAlign.center,
          style: AppTextStyles.hint,
        ),
        const SizedBox(height: 22),
        FilledButton(
          key: const Key('resume_button'),
          onPressed: onResume,
          child: const Text('Resume'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: const Key('menu_button'),
          onPressed: onMenu,
          child: const Text('Menu'),
        ),
      ],
    );
  }
}

class _GameOverCard extends StatelessWidget {
  const _GameOverCard({
    required this.score,
    required this.best,
    required this.newBest,
    required this.onAgain,
    required this.onMenu,
  });

  final double score;
  final int best;
  final bool newBest;
  final VoidCallback onAgain;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      children: [
        Text(
          newBest ? 'New best' : 'Run over',
          textAlign: TextAlign.center,
          style: AppTextStyles.eyebrow.copyWith(
            color: newBest ? AppColors.accent : AppColors.secondary,
          ),
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(formatScore(score), style: AppTextStyles.scoreLarge),
        ),
        const SizedBox(height: 8),
        Text(
          'Best ${formatScore(best)}',
          textAlign: TextAlign.center,
          style: AppTextStyles.hint,
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          key: const Key('again_button'),
          onPressed: onAgain,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Fly again'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: onMenu, child: const Text('Menu')),
      ],
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
