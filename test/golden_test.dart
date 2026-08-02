// Article 6 — golden (visual-regression) test. Pure shapes only, so it renders
// deterministically in headless CI. Baseline lives in test/goldens/banner.png;
// regenerate intentionally with:  flutter test --update-goldens

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('brand banner matches golden', (tester) async {
    await tester.pumpWidget(
      const RepaintBoundary(
        key: Key('banner'),
        child: SizedBox(
          width: 200,
          height: 100,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2962FF), Color(0xFF00B0FF)],
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 56,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(const Key('banner')),
      matchesGoldenFile('goldens/banner.png'),
    );
  });
}
