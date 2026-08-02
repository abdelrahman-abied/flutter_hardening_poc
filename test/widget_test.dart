import 'package:flutter_test/flutter_test.dart';
import 'package:hardening_poc/main.dart';

void main() {
  testWidgets('home screen lists all demos', (tester) async {
    await tester.pumpWidget(const HardeningPocApp());
    await tester.pump();

    expect(find.text('Flutter Hardening PoC'), findsOneWidget);
    expect(find.text('RASP verdict'), findsOneWidget);
    expect(find.text('Encryption envelope'), findsOneWidget);
    expect(find.text('Jank: rebuild scope'), findsOneWidget);
    expect(find.text('Concurrency & FFI'), findsOneWidget);
  });
}
