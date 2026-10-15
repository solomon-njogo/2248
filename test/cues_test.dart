import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_2248/cues/cues.dart';

void main() {
  test('a step on Android pulses the motor for 40 ms at half strength', () {
    final motor = MotorRecorder();
    final impacts = ImpactRecorder();
    PlatformCues(
      motor: motor,
      impacts: impacts,
      platform: TargetPlatform.android,
    ).play(const Cue.step(60, tone: false));

    expect(motor.pulses, [const Pulse(40, 128)]);
    expect(impacts.lights, 0);
    expect(impacts.mediums, 0);
  });

  test('a resolve on Android pulses the motor for 80 ms at full strength', () {
    final motor = MotorRecorder();
    PlatformCues(
      motor: motor,
      impacts: ImpactRecorder(),
      platform: TargetPlatform.android,
    ).play(const Cue.resolve(60, tone: false));

    expect(motor.pulses, [const Pulse(80, 255)]);
  });

  test('a clear, a refresh, and an abandon on Android are short pulses', () {
    final motor = MotorRecorder();
    final cues = PlatformCues(
      motor: motor,
      impacts: ImpactRecorder(),
      platform: TargetPlatform.android,
    );
    cues.play(const Cue.clear(tone: false));
    cues.play(const Cue.refresh(tone: false));
    cues.play(const Cue.abandon());

    expect(motor.pulses, [
      const Pulse(40, 128),
      const Pulse(40, 128),
      const Pulse(40, 128),
    ]);
  });

  test('a step on iPhone is a light system impact', () {
    final motor = MotorRecorder();
    final impacts = ImpactRecorder();
    PlatformCues(
      motor: motor,
      impacts: impacts,
      platform: TargetPlatform.iOS,
    ).play(const Cue.step(60, tone: false));

    expect(motor.pulses, isEmpty);
    expect(impacts.lights, 1);
    expect(impacts.mediums, 0);
  });

  test('a resolve on iPhone is a medium system impact', () {
    final impacts = ImpactRecorder();
    PlatformCues(
      motor: MotorRecorder(),
      impacts: impacts,
      platform: TargetPlatform.iOS,
    ).play(const Cue.resolve(60, tone: false));

    expect(impacts.lights, 0);
    expect(impacts.mediums, 1);
  });

  test('a clear, a refresh, and an abandon on iPhone are light impacts', () {
    final impacts = ImpactRecorder();
    final cues = PlatformCues(
      motor: MotorRecorder(),
      impacts: impacts,
      platform: TargetPlatform.iOS,
    );
    cues.play(const Cue.clear(tone: false));
    cues.play(const Cue.refresh(tone: false));
    cues.play(const Cue.abandon());

    expect(impacts.lights, 3);
    expect(impacts.mediums, 0);
  });

  test('a step on Windows stays quiet', () {
    final motor = MotorRecorder();
    final impacts = ImpactRecorder();
    PlatformCues(
      motor: motor,
      impacts: impacts,
      platform: TargetPlatform.windows,
    ).play(const Cue.step(60, tone: false));

    expect(motor.pulses, isEmpty);
    expect(impacts.lights, 0);
    expect(impacts.mediums, 0);
  });

  test('a second join is its own short pulse', () {
    final motor = MotorRecorder();
    final cues = PlatformCues(
      motor: motor,
      impacts: ImpactRecorder(),
      platform: TargetPlatform.android,
    );
    cues.play(const Cue.step(60, tone: false));
    cues.play(const Cue.step(62, tone: false));

    expect(motor.pulses, [const Pulse(40, 128), const Pulse(40, 128)]);
  });

  test('the Android motor sends the pulse length and strength to the phone', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('com.game2248.remastered/motor');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    const ChannelMotor().pulse(const Pulse(40, 128));

    expect(calls, [
      isMethodCall('pulse', arguments: {'millis': 40, 'amplitude': 128}),
    ]);
  });
}

class MotorRecorder implements Motor {
  final pulses = <Pulse>[];

  @override
  void pulse(Pulse pulse) => pulses.add(pulse);
}

class ImpactRecorder implements Impacts {
  var lights = 0;
  var mediums = 0;

  @override
  void light() => lights++;

  @override
  void medium() => mediums++;
}
