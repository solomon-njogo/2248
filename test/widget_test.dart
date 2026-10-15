import 'package:flutter_test/flutter_test.dart';
import 'package:game_2248/main.dart';

void main() {
  testWidgets('shows hello world', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Hello World'), findsOneWidget);
  });
}
