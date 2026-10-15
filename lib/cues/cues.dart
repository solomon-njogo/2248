import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum CueKind { step, resolve, clear, refresh, abandon }

class Cue {
  const Cue.step(this.midi, {required this.tone})
    : kind = CueKind.step,
      haptic = true;

  const Cue.resolve(this.midi, {required this.tone})
    : kind = CueKind.resolve,
      haptic = true;

  const Cue.clear({required this.tone})
    : kind = CueKind.clear,
      midi = null,
      haptic = true;

  const Cue.refresh({required this.tone})
    : kind = CueKind.refresh,
      midi = null,
      haptic = true;

  const Cue.abandon()
    : kind = CueKind.abandon,
      midi = null,
      tone = false,
      haptic = true;

  final CueKind kind;
  final int? midi;
  final bool tone;
  final bool haptic;

  @override
  bool operator ==(Object other) =>
      other is Cue &&
      other.kind == kind &&
      other.midi == midi &&
      other.tone == tone &&
      other.haptic == haptic;

  @override
  int get hashCode => Object.hash(kind, midi, tone, haptic);

  @override
  String toString() =>
      'Cue(${kind.name}, midi: $midi, tone: $tone, haptic: $haptic)';
}

class Pulse {
  const Pulse(this.millis, this.amplitude);

  final int millis;
  final int amplitude;

  @override
  bool operator ==(Object other) =>
      other is Pulse && other.millis == millis && other.amplitude == amplitude;

  @override
  int get hashCode => Object.hash(millis, amplitude);
}

abstract class Motor {
  void pulse(Pulse pulse);
}

abstract class Impacts {
  void light();

  void medium();
}

class ChannelMotor implements Motor {
  const ChannelMotor();

  static const _channel = MethodChannel('com.game2248.remastered/motor');

  @override
  void pulse(Pulse pulse) {
    _channel.invokeMethod<void>('pulse', {
      'millis': pulse.millis,
      'amplitude': pulse.amplitude,
    });
  }
}

class FlutterImpacts implements Impacts {
  const FlutterImpacts();

  @override
  void light() => HapticFeedback.lightImpact();

  @override
  void medium() => HapticFeedback.mediumImpact();
}

abstract class Cues {
  void play(Cue cue);

  void dispose() {}
}

class CueRecorder implements Cues {
  final events = <Cue>[];

  @override
  void play(Cue cue) => events.add(cue);

  @override
  void dispose() {}
}

int pitchOf(int value) {
  var power = 1;
  var index = -1;
  while (power < value) {
    power *= 2;
    index++;
  }
  const degrees = [0, 2, 4, 7, 9];
  return 60 + (index ~/ 5) * 12 + degrees[index % 5];
}

class PlatformCues implements Cues {
  PlatformCues({
    Motor? motor,
    Impacts? impacts,
    TargetPlatform? platform,
    AudioPlayer? player,
  }) : _motor = motor ?? const ChannelMotor(),
       _impacts = impacts ?? const FlutterImpacts(),
       _platform = platform ?? defaultTargetPlatform,
       _player = player;

  final Motor _motor;
  final Impacts _impacts;
  final TargetPlatform _platform;
  AudioPlayer? _player;

  @override
  void play(Cue cue) {
    if (cue.haptic && _platform == TargetPlatform.android) {
      _motor.pulse(
        cue.kind == CueKind.resolve
            ? const Pulse(80, 255)
            : const Pulse(40, 128),
      );
    } else if (cue.haptic && _platform == TargetPlatform.iOS) {
      if (cue.kind == CueKind.resolve) {
        _impacts.medium();
      } else {
        _impacts.light();
      }
    }
    if (!cue.tone) return;
    final player = _player ??= AudioPlayer();
    player.play(BytesSource(_tone(cue)));
  }

  @override
  void dispose() {
    _player?.dispose();
  }

  Uint8List _tone(Cue cue) {
    switch (cue.kind) {
      case CueKind.step:
        return _sine(midi: cue.midi ?? 60, millis: 45, amplitude: 0.22);
      case CueKind.resolve:
        return _sine(midi: cue.midi ?? 60, millis: 180, amplitude: 0.5);
      case CueKind.clear:
        return _sweep(fromHz: 660, toHz: 180, millis: 180, amplitude: 0.28);
      case CueKind.refresh:
        return _sine(midi: 48, millis: 180, amplitude: 0.12);
      case CueKind.abandon:
        return Uint8List(0);
    }
  }

  Uint8List _sine({
    required int midi,
    required int millis,
    required double amplitude,
  }) {
    final hz = 440 * math.pow(2, (midi - 69) / 12);
    return _samples(millis, amplitude, (i, samples) {
      final env = _envelope(i, samples);
      return math.sin(2 * math.pi * hz * i / _sampleRate) * env;
    });
  }

  Uint8List _sweep({
    required double fromHz,
    required double toHz,
    required int millis,
    required double amplitude,
  }) {
    return _samples(millis, amplitude, (i, samples) {
      final t = i / samples;
      final hz = fromHz + (toHz - fromHz) * t;
      return math.sin(2 * math.pi * hz * i / _sampleRate) *
          _envelope(i, samples);
    });
  }

  Uint8List _samples(
    int millis,
    double amplitude,
    double Function(int index, int samples) wave,
  ) {
    final count = (_sampleRate * millis / 1000).round();
    final data = ByteData(44 + count * 2);
    _writeAscii(data, 0, 'RIFF');
    data.setUint32(4, 36 + count * 2, Endian.little);
    _writeAscii(data, 8, 'WAVE');
    _writeAscii(data, 12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, _sampleRate, Endian.little);
    data.setUint32(28, _sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    _writeAscii(data, 36, 'data');
    data.setUint32(40, count * 2, Endian.little);
    for (var i = 0; i < count; i++) {
      final sample = (wave(i, count) * amplitude * 32767).round().clamp(
        -32768,
        32767,
      );
      data.setInt16(44 + i * 2, sample, Endian.little);
    }
    return data.buffer.asUint8List();
  }

  double _envelope(int index, int count) {
    final attack = (count * 0.08).clamp(1, count);
    final release = (count * 0.25).clamp(1, count);
    if (index < attack) return index / attack;
    if (index > count - release) return (count - index) / release;
    return 1;
  }

  void _writeAscii(ByteData data, int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }
}

const _sampleRate = 44100;
