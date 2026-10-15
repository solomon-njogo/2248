import 'dart:io';

import 'package:game_2248/resolve/resolve_engine.dart';
import 'package:game_2248/run/file_archive.dart';
import 'package:game_2248/run/sound_memory.dart';
import 'package:path_provider/path_provider.dart';

Future<({RunStore store, SoundMemory sound})> openSavedRun() async {
  final directory = await getApplicationSupportDirectory();
  return (
    store: RunStore(
      archive: FileRunArchive(File('${directory.path}/run.json')),
    ),
    sound: SoundMemory(
      archive: FileSoundArchive(File('${directory.path}/sound.json')),
    ),
  );
}
