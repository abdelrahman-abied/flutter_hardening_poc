// Article 5 — proves isolate correctness and zero-copy transfer integrity.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hardening_poc/services/concurrency.dart';

void main() {
  test('heavyCompute is deterministic', () {
    expect(heavyCompute(50000), heavyCompute(50000));
  });

  test('isolate produces the same result as the UI thread', () async {
    final onMain = await computeOnMain(100000);
    final onIsolate = await computeOnIsolate(100000);
    expect(onIsolate.value, onMain.value,
        reason: 'moving work off-thread must not change the answer');
  });

  test('TransferableTypedData moves bytes intact (O(1) ownership)', () async {
    final data =
        Uint8List.fromList(List.generate(64 * 1024, (i) => (i * 7) & 0xFF));
    final local = checksum(data);
    final moved = await transferAndChecksum(data);
    expect(moved, local,
        reason: 'transferred buffer must be byte-identical');
  });
}
