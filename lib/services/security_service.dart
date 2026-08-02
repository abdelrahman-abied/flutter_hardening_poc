// Article 1 — RASP verdict.
//
// A structured verdict, not a boolean. The POC runs the checks it can without
// device-only plugins (debug-build detection + the native FFI anti-tamper
// scan), and clearly marks the plugin-backed checks (root/jailbreak, emulator)
// as "unavailable" here — because honest reporting is the whole point of the
// series. On a real device you'd wire flutter_jailbreak_detection + safe_device.

import 'package:flutter/foundation.dart';
import 'native_security_bridge.dart';

enum CheckStatus { pass, fail, unavailable }

class SecurityCheck {
  final String name;
  final CheckStatus status;
  final String detail;
  const SecurityCheck(this.name, this.status, this.detail);
}

class SecurityVerdict {
  final List<SecurityCheck> checks;
  const SecurityVerdict(this.checks);

  bool get anySignal => checks.any((c) => c.status == CheckStatus.fail);
}

class SecurityService {
  static Future<SecurityVerdict> scan() async {
    final checks = <SecurityCheck>[];

    // 1) Debug build detection — real, works everywhere.
    checks.add(SecurityCheck(
      'Debug build',
      kDebugMode ? CheckStatus.fail : CheckStatus.pass,
      kDebugMode
          ? 'Running in debug — RASP would run relaxed in dev'
          : 'Release/profile build',
    ));

    // 2) Native anti-tamper via FFI — real on Android, unavailable on host.
    final native = NativeSecurityBridge.scan();
    if (!native.available) {
      checks.add(const SecurityCheck(
        'Native anti-Frida (FFI)',
        CheckStatus.unavailable,
        'libanti_tamper.so loads on an Android device build',
      ));
    } else {
      checks.add(SecurityCheck(
        'Native anti-Frida (FFI)',
        native.clean ? CheckStatus.pass : CheckStatus.fail,
        native.clean
            ? 'No Frida artifacts in maps/threads'
            : 'Tamper flags: ${native.flags}',
      ));
    }

    // 3) Plugin-backed checks — honestly marked as not wired in this POC.
    checks.add(const SecurityCheck(
      'Root / Jailbreak',
      CheckStatus.unavailable,
      'Add flutter_jailbreak_detection and run on a device',
    ));
    checks.add(const SecurityCheck(
      'Emulator / real device',
      CheckStatus.unavailable,
      'Add safe_device and run on a device',
    ));

    return SecurityVerdict(checks);
  }
}
