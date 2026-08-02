// Article 3 — THE proof: rebuild scoping. This test asserts that the scoped
// demo rebuilds only the leaf (expensive boxes build exactly once), while the
// unscoped demo rebuilds the whole subtree on every tick.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hardening_poc/screens/jank_screen.dart';

Future<void> _tick6(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

List<CountingBoxState> _boxes(WidgetTester tester) =>
    tester.stateList<CountingBoxState>(find.byType(CountingBox)).toList();

void main() {
  testWidgets('SCOPED: expensive boxes build exactly once', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ScopedDemo())));
    await _tick6(tester);

    final boxes = _boxes(tester);
    expect(boxes, hasLength(2));
    for (final b in boxes) {
      expect(b.builds, 1,
          reason: 'scoped: only the ValueListenableBuilder leaf should rebuild');
    }

    await tester.pumpWidget(const SizedBox()); // unmount → cancels the timer
  });

  testWidgets('UNSCOPED: expensive boxes rebuild every tick', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: UnscopedDemo())));
    await _tick6(tester);

    final boxes = _boxes(tester);
    expect(boxes, hasLength(2));
    for (final b in boxes) {
      expect(b.builds, greaterThan(1),
          reason: 'unscoped: setState at the top rebuilds the whole subtree');
    }

    await tester.pumpWidget(const SizedBox());
  });
}
