// Article 4 & 6 — performance-regression harness.
// Records frame build/raster timings while scrolling; the driver writes them to
// build/integration_response_data.json, which CI thresholds (see tool/).
//
// Run on a real device in profile mode:
//   flutter drive \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/perf_test.dart \
//     --profile

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hardening_poc/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home scroll stays under the frame budget', (tester) async {
    await tester.pumpWidget(const HardeningPocApp());
    await tester.pumpAndSettle();

    await binding.watchPerformance(() async {
      final scrollable = find.byType(Scrollable).first;
      for (var i = 0; i < 5; i++) {
        await tester.fling(scrollable, const Offset(0, -400), 2000);
        await tester.pumpAndSettle();
        await tester.fling(scrollable, const Offset(0, 400), 2000);
        await tester.pumpAndSettle();
      }
    }, reportKey: 'home_scroll');
  });
}
