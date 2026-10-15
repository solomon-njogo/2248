import 'package:game_2248/resolve/resolve_engine.dart';
import 'package:game_2248/run/sound_memory.dart';

Future<({RunStore store, SoundMemory sound})> openSavedRun() async {
  return (store: RunStore(), sound: SoundMemory());
}
