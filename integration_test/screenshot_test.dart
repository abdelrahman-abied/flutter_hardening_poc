// Captures one screenshot per demo screen, for the article assets.
//
// Navigation is by widget text, not tap coordinates, so it stays correct if
// the home list is reordered.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:hardening_poc/main.dart';

Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Required on Android before takeScreenshot: renders the Flutter surface
  // into an image inside the app process. This also sidesteps FLAG_SECURE,
  // which blocks OS-level capture (`adb screencap`) but not this path.
  setUpAll(() async {
    await binding.convertFlutterSurfaceToImage();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    await settle(tester);
    await binding.takeScreenshot(name);
  }

  /// Opens a demo from the home list by its title, shoots it, and returns home.
  Future<void> capture(
    WidgetTester tester,
    String title,
    String outputName, {
    Future<void> Function(WidgetTester tester)? interact,
  }) async {
    final tile = find.text(title);
    await tester.scrollUntilVisible(tile, 120,
        scrollable: find.byType(Scrollable).first);
    await settle(tester);
    await tester.tap(tile);
    await settle(tester);

    if (interact != null) {
      await interact(tester);
      await settle(tester);
    }

    await shoot(tester, outputName);

    // Back to the home list. Popping the navigator directly is immune to
    // AppBar/back-button variations between screens.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pop();
    await settle(tester);
  }

  testWidgets('capture every demo screen', (tester) async {
    await tester.pumpWidget(const HardeningPocApp());
    await settle(tester);

    await shoot(tester, 'home');

    await capture(tester, 'RASP verdict', 'article_1_rasp');
    await capture(tester, 'Encryption envelope', 'article_2_envelope',
        interact: (t) async {
      final run = find.textContaining('Run X25519');
      if (run.evaluate().isNotEmpty) await t.tap(run.first);
    });
    await capture(tester, 'Jank: rebuild scope', 'article_3_jank');
    await capture(tester, 'Image memory budget', 'article_3_image_memory');
    await capture(tester, 'CustomPainter cost', 'article_4_painter');
    await capture(tester, 'Concurrency & FFI', 'article_5_concurrency');
    await capture(tester, 'Attack surface', 'article_7_attack_surface');
    await capture(tester, 'Hardened WebView', 'article_7_hardened_webview',
        interact: (t) async {
      // Ask the WebView to navigate somewhere hostile; the delegate refuses
      // it and the on-screen log records the verdict.
      final hostile = find.textContaining('hostile host');
      if (hostile.evaluate().isNotEmpty) {
        await t.tap(hostile.first);
        for (var i = 0; i < 6; i++) {
          await t.pump(const Duration(milliseconds: 500));
        }
      }
    });
    await capture(tester, 'Quiet leaks', 'article_8_quiet_leaks');
    await capture(tester, 'SQL injection', 'article_8_sql_injection');
    await capture(tester, 'Trust decision', 'article_9_trust_decision');
    await capture(tester, 'Biometric gate', 'article_9_biometric',
        interact: (t) async {
      // Flip the patched-client switch so the client-vs-server divergence —
      // the whole point of Article 9 — is visible even on an emulator with
      // no enrolled biometrics.
      final toggle = find.byType(SwitchListTile);
      if (toggle.evaluate().isNotEmpty) await t.tap(toggle.first);
    });
  });
}
