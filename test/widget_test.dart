import 'package:game_2248/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('menu can start a run', (tester) async {
    await tester.pumpWidget(const AetherApp());
    await tester.pump();

    expect(find.text('AETHER'), findsOneWidget);
    expect(find.text('No record yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('play_button')));
    await tester.pump();

    expect(find.byKey(const Key('pause_button')), findsOneWidget);
    expect(find.byKey(const Key('shield_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pause_button')));
    await tester.pump();

    expect(find.text('Paused'), findsOneWidget);
    await tester.tap(find.byKey(const Key('resume_button')));
    await tester.pump();

    expect(find.text('Paused'), findsNothing);
  });

  testWidgets('animating the menu does not break the element tree', (
    tester,
  ) async {
    await tester.pumpWidget(const AetherApp());
    await tester.pump();
    for (var frame = 0; frame < 120; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.takeException(), isNull);
    expect(find.text('AETHER'), findsOneWidget);

    await tester.tap(find.byKey(const Key('play_button')));
    for (var frame = 0; frame < 180; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu and play fit a phone and a short window', (tester) async {
    await _pumpAt(tester, const Size(390, 844));
    expect(find.text('AETHER'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('play_button')));
    await tester.pump();
    expect(find.byKey(const Key('shield_button')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _pumpAt(tester, const Size(844, 390));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const AetherApp());
  await tester.pump();
}
