// Article 8 — decoding a JWT is not verifying it (CWE-347).
//
// Everything here runs client-side and proves a single point: the client can
// read a token's claims, and it can just as easily FORGE them. Signature
// verification belongs on the server, with a pinned algorithm and key.

import 'dart:convert';

class JwtParts {
  final Map<String, dynamic> header;
  final Map<String, dynamic> payload;
  final String signature;

  const JwtParts({
    required this.header,
    required this.payload,
    required this.signature,
  });

  String? get algorithm => header['alg'] as String?;

  bool get hasSignature => signature.isNotEmpty;

  /// The giveaway of a forged token — but only the SERVER may act on it.
  bool get claimsNoSignature =>
      algorithm == null || algorithm!.toLowerCase() == 'none';

  int? get expiresAtSeconds => switch (payload['exp']) {
        final int v => v,
        final String v => int.tryParse(v),
        _ => null,
      };

  /// Safe client-side use of `exp`: refresh proactively instead of firing
  /// requests that are already doomed. A missing `exp` counts as invalid.
  bool isExpiredAt(DateTime now) {
    final exp = expiresAtSeconds;
    if (exp == null) return true;
    return now.millisecondsSinceEpoch ~/ 1000 >= exp;
  }
}

class JwtInspect {
  static Map<String, dynamic> _decodeSegment(String segment) {
    final decoded = utf8.decode(base64Url.decode(base64Url.normalize(segment)));
    final value = json.decode(decoded);
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }

  static String _encodeSegment(Map<String, dynamic> map) =>
      base64Url.encode(utf8.encode(json.encode(map))).replaceAll('=', '');

  /// Reads a token WITHOUT verifying it. Returns null for malformed input.
  ///
  /// Nothing this returns may be used for an authorization decision.
  static JwtParts? decodeWithoutVerifying(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      return JwtParts(
        header: _decodeSegment(parts[0]),
        payload: _decodeSegment(parts[1]),
        signature: parts.length > 2 ? parts[2] : '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Builds an unsigned token, for demonstration only.
  static String mintUnsigned(Map<String, dynamic> payload) {
    final header = <String, dynamic>{'alg': 'HS256', 'typ': 'JWT'};
    return '${_encodeSegment(header)}.${_encodeSegment(payload)}.c2lnbmF0dXJl';
  }

  /// The `alg: none` attack, in six lines: take a token, rewrite the claims,
  /// declare the token unsigned, drop the signature, re-encode.
  ///
  /// A client that authorizes on decoded claims cannot tell this from the
  /// real thing. A server with a pinned algorithm rejects it instantly.
  static String forgeAlgNone(String token, Map<String, dynamic> overrides) {
    final parts = decodeWithoutVerifying(token);
    final payload = <String, dynamic>{...?parts?.payload, ...overrides};
    final header = <String, dynamic>{'alg': 'none', 'typ': 'JWT'};
    return '${_encodeSegment(header)}.${_encodeSegment(payload)}.';
  }

  /// The anti-pattern from the article: an entitlement read straight off an
  /// unverified claim. Present so a test can prove it is trivially defeated.
  static bool clientSideIsAdmin(String token) =>
      decodeWithoutVerifying(token)?.payload['role'] == 'admin';
}
