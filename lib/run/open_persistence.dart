import 'package:game_2248/resolve/resolve_engine.dart';
import 'package:game_2248/run/sound_memory.dart';

import 'open_persistence_stub.dart'
    if (dart.library.io) 'open_persistence_io.dart'
    as impl;

Future<({RunStore store, SoundMemory sound})> openSavedRun() =>
    impl.openSavedRun();
