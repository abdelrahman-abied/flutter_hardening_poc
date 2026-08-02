// Article 2 — proves the encryption envelope.

import 'package:flutter_test/flutter_test.dart';
import 'package:hardening_poc/services/secure_envelope.dart';

void main() {
  test('both parties derive the same key without transmitting it', () async {
    final r = await SecureEnvelope.demoRoundTrip('transfer \$500');
    expect(r.sharedSecretsMatch, isTrue,
        reason: 'X25519 ECDH must produce identical shared secrets');
  });

  test('AES-GCM ciphertext decrypts back to the original', () async {
    final r = await SecureEnvelope.demoRoundTrip('sensitive payload');
    expect(r.roundTripOk, isTrue);
    expect(r.decrypted, 'sensitive payload');
  });

  test('a fresh 96-bit GCM nonce is used', () async {
    final r = await SecureEnvelope.demoRoundTrip('x');
    expect(r.nonceHex.length, 24, reason: '12-byte nonce = 24 hex chars');
  });

  test('two runs produce different nonces and ciphertext', () async {
    final a = await SecureEnvelope.demoRoundTrip('same message');
    final b = await SecureEnvelope.demoRoundTrip('same message');
    expect(a.nonceHex == b.nonceHex, isFalse,
        reason: 'nonce must never repeat for a given key');
    expect(a.ciphertextHex == b.ciphertextHex, isFalse);
  });
}
