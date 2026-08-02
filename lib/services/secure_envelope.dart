// Article 2 — Application-layer encryption envelope.
// X25519 (ECDH) -> HKDF-SHA256 -> AES-256-GCM.
//
// This proves the core claim of Article 2: two parties derive the SAME
// symmetric key WITHOUT ever transmitting it, then exchange an authenticated,
// tamper-evident ciphertext. Run the demo or the unit test to see it round-trip.

import 'dart:convert';
import 'package:cryptography/cryptography.dart';

/// Structured result of a full client<->server envelope exchange, for display.
class EnvelopeResult {
  final String clientPublicKey; // hex
  final String serverPublicKey; // hex
  final bool sharedSecretsMatch; // both sides derived the same key?
  final String ciphertextHex;
  final String nonceHex;
  final String macHex;
  final String decrypted;
  final bool roundTripOk;

  const EnvelopeResult({
    required this.clientPublicKey,
    required this.serverPublicKey,
    required this.sharedSecretsMatch,
    required this.ciphertextHex,
    required this.nonceHex,
    required this.macHex,
    required this.decrypted,
    required this.roundTripOk,
  });
}

class SecureEnvelope {
  static final _x25519 = X25519();
  static final _aead = AesGcm.with256bits();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  /// Derive a session key from *my* private key + *their* public key.
  /// The shared secret is computed locally on both ends — never sent.
  static Future<SecretKey> deriveSessionKey(
    SimpleKeyPair mine,
    SimplePublicKey theirs,
  ) async {
    final shared =
        await _x25519.sharedSecretKey(keyPair: mine, remotePublicKey: theirs);
    // Never use the raw ECDH output directly — run it through a KDF.
    return _hkdf.deriveKey(
      secretKey: shared,
      nonce: const <int>[],
      info: utf8.encode('hardening_poc/v1/session'),
    );
  }

  /// Full client<->server exchange + encrypt + decrypt, for the demo screen.
  static Future<EnvelopeResult> demoRoundTrip(String message) async {
    // Two independent parties.
    final client = await _x25519.newKeyPair();
    final server = await _x25519.newKeyPair();
    final clientPub = await client.extractPublicKey();
    final serverPub = await server.extractPublicKey();

    // Each side derives the session key from its own private + peer's public.
    final clientKey = await deriveSessionKey(client, serverPub);
    final serverKey = await deriveSessionKey(server, clientPub);

    final clientBytes = await clientKey.extractBytes();
    final serverBytes = await serverKey.extractBytes();
    final match = _constTimeEq(clientBytes, serverBytes);

    // Client seals; server opens — with the independently-derived key.
    final box = await _aead.encrypt(utf8.encode(message), secretKey: clientKey);
    final opened = await _aead.decrypt(box, secretKey: serverKey);
    final decrypted = utf8.decode(opened);

    return EnvelopeResult(
      clientPublicKey: _hex(clientPub.bytes),
      serverPublicKey: _hex(serverPub.bytes),
      sharedSecretsMatch: match,
      ciphertextHex: _hex(box.cipherText),
      nonceHex: _hex(box.nonce),
      macHex: _hex(box.mac.bytes),
      decrypted: decrypted,
      roundTripOk: decrypted == message,
    );
  }

  static bool _constTimeEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
