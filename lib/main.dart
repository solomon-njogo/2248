import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:game_2248/cues/cues.dart';
import 'package:game_2248/play/play_screen.dart';
import 'package:game_2248/resolve/resolve_engine.dart';
import 'package:game_2248/run/open_persistence.dart';
import 'package:game_2248/run/sound_memory.dart';
import 'package:game_2248/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final saved = await openSavedRun();
  runApp(MyApp(store: saved.store, sound: saved.sound, cues: PlatformCues()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.engine, this.store, this.cues, this.sound});

  final ResolveEngine? engine;
  final RunStore? store;
  final Cues? cues;
  final SoundMemory? sound;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ResolveEngine _engine;
  late RunStore _store;
  late Cues _cues;
  late SoundMemory _sound;
  late bool _ownsCues;

  @override
  void initState() {
    super.initState();
    _engine = widget.engine ?? ResolveEngine();
    _store = widget.store ?? RunStore();
    _ownsCues = widget.cues == null;
    _cues = widget.cues ?? PlatformCues();
    _sound = widget.sound ?? SoundMemory();
  }

  @override
  void didUpdateWidget(MyApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.engine != null) _engine = widget.engine!;
    if (widget.store != null) _store = widget.store!;
    if (widget.cues != null) {
      if (_ownsCues && _cues != widget.cues) _cues.dispose();
      _ownsCues = false;
      _cues = widget.cues!;
    }
    if (widget.sound != null) _sound = widget.sound!;
  }

  @override
  void dispose() {
    if (_ownsCues) _cues.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: MaterialApp(
        title: '2248',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          for (final code in kMaterialSupportedLanguages) Locale(code),
        ],
        home: PlayScreen(
          key: ValueKey(
            Object.hash(
              identityHashCode(_engine),
              identityHashCode(_store),
              identityHashCode(_cues),
              identityHashCode(_sound),
            ),
          ),
          engine: _engine,
          store: _store,
          cues: _cues,
          sound: _sound,
        ),
      ),
    );
  }
}
