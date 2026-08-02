// Article 1 — Dart FFI bridge to the native anti-tamper engine.
//
// On Android this loads libanti_tamper.so (compiled from
// android/app/src/main/cpp/anti_tamper.cpp via CMake) and calls the exported
// `scan_environment()`, returning a bitmask of tripped detection vectors.
//
// On the host (unit tests / desktop) the library isn't present, so the bridge
// reports `available: false` and the UI shows "native scan unavailable here"
// rather than a false verdict.

import 'dart:ffi';
import 'dart:io';

/// Bitmask flags mirrored from the native side (see anti_tamper.cpp).
class TamperFlags {
  static const int clean = 0;
  static const int fridaInMaps = 1 << 0;
  static const int fridaThreadName = 1 << 1;
}

class NativeScanResult {
  final bool available;
  final int flags;
  const NativeScanResult({required this.available, required this.flags});

  bool get clean => flags == TamperFlags.clean;
}

typedef _ScanNative = Int32 Function();
typedef _ScanDart = int Function();

class NativeSecurityBridge {
  static _ScanDart? _scan;
  static bool _tried = false;

  static void _ensureInit() {
    if (_tried) return;
    _tried = true;
    try {
      final lib = Platform.isAndroid
          ? DynamicLibrary.open('libanti_tamper.so')
          : DynamicLibrary.process();
      _scan = lib
          .lookup<NativeFunction<_ScanNative>>('scan_environment')
          .asFunction<_ScanDart>();
    } catch (_) {
      _scan = null; // library/symbol not available on this platform
    }
  }

  static NativeScanResult scan() {
    _ensureInit();
    final fn = _scan;
    if (fn == null) {
      return const NativeScanResult(available: false, flags: 0);
    }
    try {
      return NativeScanResult(available: true, flags: fn());
    } catch (_) {
      // Fail closed: if the check itself errors, treat as compromised.
      return const NativeScanResult(available: true, flags: TamperFlags.fridaInMaps);
    }
  }
}
