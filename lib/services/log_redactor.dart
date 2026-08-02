// Article 8 — sensitive data in logs (CWE-532).
//
// The real threat isn't other apps reading logcat (impossible since Android
// 4.1 — READ_LOGS is privileged). It's crash/analytics SDKs uploading recent
// log lines as breadcrumbs, `adb logcat` over USB, and user-submitted bug
// reports. And note: print/debugPrint are NOT stripped from release builds.

import 'package:flutter/foundation.dart';

class LogRedactor {
  static const placeholder = '«redacted»';

  /// A JSON Web Token anywhere in the line.
  static final _jwt = RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*');

  /// `Authorization: Bearer <token>`.
  static final _bearer = RegExp(
    r'(Bearer\s+)[A-Za-z0-9._~+/=-]+',
    caseSensitive: false,
  );

  /// `token=…`, `"password": "…"`, `secret : …` and friends. Triple-quoted raw
  /// string so the pattern can contain both quote characters. The optional
  /// `Bearer` prefix is kept out of the captured value so the scheme stays
  /// readable in logs while the credential itself does not.
  static final _keyValue = RegExp(
    r'''((?:token|password|passwd|secret|otp|pin|ssn|api[_-]?key|authorization)["']?\s*[:=]\s*["']?(?:Bearer\s+)?)([^\s,;"'}\]]+)''',
    caseSensitive: false,
  );

  /// Card-number-shaped digit runs.
  static final _pan = RegExp(r'\b\d{13,19}\b');

  /// Masks known secret shapes. Defence in depth, not a guarantee — the only
  /// reliable rule is not to log the secret in the first place.
  static String redact(String line) {
    var out = line.replaceAll(_jwt, placeholder);
    out = out.replaceAllMapped(_bearer, (m) => '${m[1]}$placeholder');
    out = out.replaceAllMapped(_keyValue, (m) => '${m[1]}$placeholder');
    out = out.replaceAll(_pan, placeholder);
    return out;
  }

  /// True if the line still contains something that looks like a secret.
  ///
  /// Defined as "redaction would change this line", which makes it exactly
  /// consistent with [redact] and correctly reports an already-redacted line
  /// as clean — [redact] is idempotent.
  static bool looksSensitive(String line) => redact(line) != line;
}

/// The logger to actually call. Redacts, then drops everything in release.
class Log {
  static void d(String message) {
    if (kReleaseMode) return; // nothing reaches production logs
    debugPrint(LogRedactor.redact(message));
  }
}
