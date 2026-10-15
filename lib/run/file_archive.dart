import 'dart:convert';
import 'dart:io';

import 'package:game_2248/resolve/resolve_engine.dart';
import 'package:game_2248/run/sound_memory.dart';

class FileRunArchive implements RunArchive {
  FileRunArchive(this.file);

  final File file;

  @override
  String? read() {
    if (!file.existsSync()) return null;
    return file.readAsStringSync();
  }

  @override
  void write(String payload) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(payload);
  }
}

class FileSoundArchive implements SoundArchive {
  FileSoundArchive(this.file);

  final File file;

  @override
  bool readMuted() {
    if (!file.existsSync()) return false;
    try {
      final json = jsonDecode(file.readAsStringSync());
      if (json is Map && json['muted'] is bool) return json['muted'] as bool;
    } on FormatException {
      return false;
    }
    return false;
  }

  @override
  void writeMuted(bool muted) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode({'muted': muted}));
  }
}
