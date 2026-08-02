// Article 8 — proves that decoding a JWT tells you nothing about its authenticity.

import 'package:flutter_test/flutter_test.dart';
import 'package:hardening_poc/services/jwt_inspect.dart';

void main() {
  final issued = JwtInspect.mintUnsigned({
    'sub': 'amy',
    'role': 'user',
    'exp': 1893456000, // 2030-01-01
  });

  test('decodes claims without any verification', () {
    final parts = JwtInspect.decodeWithoutVerifying(issued)!;
    expect(parts.payload['sub'], 'amy');
    expect(parts.payload['role'], 'user');
    expect(parts.algorithm, 'HS256');
    expect(parts.hasSignature, isTrue);
  });

  test('returns null on malformed input instead of throwing', () {
    expect(JwtInspect.decodeWithoutVerifying('not-a-token'), isNull);
    expect(JwtInspect.decodeWithoutVerifying(''), isNull);
    expect(JwtInspect.decodeWithoutVerifying('!!!.???.###'), isNull);
  });

  test('THE ATTACK: alg:none forgery flips the role and the client agrees', () {
    expect(JwtInspect.clientSideIsAdmin(issued), isFalse);

    final forged = JwtInspect.forgeAlgNone(issued, {'role': 'admin'});

    expect(JwtInspect.clientSideIsAdmin(forged), isTrue,
        reason: 'a client that authorizes on decoded claims is defeated here');

    final parts = JwtInspect.decodeWithoutVerifying(forged)!;
    expect(parts.algorithm, 'none');
    expect(parts.hasSignature, isFalse);
    expect(parts.claimsNoSignature, isTrue,
        reason: 'the server, with a pinned algorithm, rejects exactly this');
  });

  test('forgery preserves the untouched claims', () {
    final forged = JwtInspect.forgeAlgNone(issued, {'role': 'admin'});
    expect(JwtInspect.decodeWithoutVerifying(forged)!.payload['sub'], 'amy');
  });

  test('exp is usable client-side only to refresh proactively', () {
    final parts = JwtInspect.decodeWithoutVerifying(issued)!;
    expect(parts.isExpiredAt(DateTime.utc(2020)), isFalse);
    expect(parts.isExpiredAt(DateTime.utc(2031)), isTrue);
  });

  test('a token with no exp counts as invalid', () {
    final noExp = JwtInspect.mintUnsigned({'sub': 'amy'});
    final parts = JwtInspect.decodeWithoutVerifying(noExp)!;
    expect(parts.expiresAtSeconds, isNull);
    expect(parts.isExpiredAt(DateTime.utc(2020)), isTrue);
  });
}
