// Article 8 — Random() is a number generator, not a secret generator.
//
// Dart's own docs: "The default implementation supplies a stream of
// pseudo-random bits that are not suitable for cryptographic purposes."
// Random.secure() "creates a cryptographically secure random number
// generator" and throws UnsupportedError rather than degrading silently.

import 'dart:math';

class Entropy {
  static String _hexFrom(Random rng, int bytes) => List.generate(
        bytes,
        (_) => rng.nextInt(256),
      ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// The bug. A seeded generator is a pure function of its seed, so this
  /// returns the SAME "token" on every call, on every machine, forever.
  static String predictableToken({int seed = 42, int bytes = 16}) =>
      _hexFrom(Random(seed), bytes);

  /// The fix. Suitable for tokens, nonces, IVs, salts, session ids, OTPs.
  static String secureToken({int bytes = 32}) =>
      _hexFrom(Random.secure(), bytes);

  /// Proof, not assertion: the same seed reproduces the stream exactly.
  static bool seededStreamRepeats({int seed = 42, int bytes = 16}) =>
      predictableToken(seed: seed, bytes: bytes) ==
      predictableToken(seed: seed, bytes: bytes);

  /// The realistic version of the bug: seeding from the clock. An attacker
  /// who can guess the minute you issued a token can enumerate the candidates.
  static List<String> tokensForTimeWindow({
    required int startMillis,
    int windowMillis = 5,
    int bytes = 16,
  }) =>
      List.generate(
        windowMillis,
        (i) => predictableToken(seed: startMillis + i, bytes: bytes),
      );

  /// Given a token minted with `Random(clock)`, how many guesses does an
  /// attacker need if they know the issuing time to within [windowMillis]?
  static int bruteForceCost({int windowMillis = 1000}) => windowMillis;
}
