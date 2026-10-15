abstract class SoundArchive {
  bool readMuted();

  void writeMuted(bool muted);
}

class SoundMemory {
  SoundMemory({SoundArchive? archive}) : _archive = archive {
    muted = archive?.readMuted() ?? false;
  }

  final SoundArchive? _archive;
  bool muted = false;

  void setMuted(bool value) {
    muted = value;
    _archive?.writeMuted(value);
  }
}
