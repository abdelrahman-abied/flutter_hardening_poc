// Article 5 — Concurrency & zero-copy transfer.
//
// Proves three things you can measure on screen / in tests:
//  1. CPU-bound work on the UI isolate blocks it (freezes the app).
//  2. The same work via Isolate.run() runs off the UI isolate (stays smooth).
//  3. TransferableTypedData moves a large buffer between isolates and the
//     bytes arrive intact (checksum matches) — an O(1) ownership move.

import 'dart:isolate';
import 'dart:typed_data';

/// Deterministic, CPU-bound work. Same input -> same output on any isolate.
int heavyCompute(int iterations) {
  var acc = 0;
  for (var i = 0; i < iterations; i++) {
    // A cheap, order-dependent mix so the compiler can't fold it away.
    acc = (acc + ((i * 2654435761) & 0xFFFF)) & 0x3FFFFFFF;
  }
  return acc;
}

class TimedResult {
  final int value;
  final int millis;
  const TimedResult(this.value, this.millis);
}

/// Runs on the calling (UI) isolate — this BLOCKS the event loop.
Future<TimedResult> computeOnMain(int iterations) async {
  final sw = Stopwatch()..start();
  final v = heavyCompute(iterations);
  sw.stop();
  return TimedResult(v, sw.elapsedMilliseconds);
}

/// Runs on a fresh background isolate — the UI isolate stays free.
Future<TimedResult> computeOnIsolate(int iterations) async {
  final sw = Stopwatch()..start();
  final v = await Isolate.run(() => heavyCompute(iterations));
  sw.stop();
  return TimedResult(v, sw.elapsedMilliseconds);
}

/// Zero-copy proof: wrap a big buffer, move it into an isolate, checksum it
/// there, and return the checksum. If the bytes survived the O(1) transfer
/// intact, the checksum matches one computed locally.
Future<int> transferAndChecksum(Uint8List big) {
  final transfer = TransferableTypedData.fromList([big]);
  return Isolate.run(() {
    final bytes = transfer.materialize().asUint8List();
    var sum = 0;
    for (final b in bytes) {
      sum = (sum + b) & 0x7FFFFFFF;
    }
    return sum;
  });
}

/// Local checksum with the same algorithm, for comparison in the demo/test.
int checksum(Uint8List bytes) {
  var sum = 0;
  for (final b in bytes) {
    sum = (sum + b) & 0x7FFFFFFF;
  }
  return sum;
}
