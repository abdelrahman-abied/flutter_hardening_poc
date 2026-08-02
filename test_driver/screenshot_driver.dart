// Screenshot driver — writes each captured frame to screenshots/<name>.png.
//
// Run with:
//   flutter drive \
//     --driver=test_driver/screenshot_driver.dart \
//     --target=integration_test/screenshot_test.dart \
//     -d <device>

import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('screenshots/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      stdout.writeln('captured screenshots/$name.png (${bytes.length} bytes)');
      return true;
    },
  );
}
