// Article 8 — proves Random() is reproducible and Random.secure() is not.

import 'package:flutter_test/flutter_test.dart';
import 'package:hardening_poc/services/entropy.dart';

void main() {
  test('a seeded Random() reproduces its token stream exactly', () {
    expect(Entropy.seededStreamRepeats(), isTrue,
        reason: 'Random(seed) is a pure function of its seed');
    expect(Entropy.predictableToken(seed: 42),
        equals(Entropy.predictableToken(seed: 42)));
  });

  test('different seeds give different tokens — which is the whole attack', () {
    expect(Entropy.predictableToken(seed: 1),
        isNot(equals(Entropy.predictableToken(seed: 2))));
  });

  test('Random.secure() does not repeat across calls', () {
    final tokens = List.generate(50, (_) => Entropy.secureToken());
    expect(tokens.toSet().length, 50,
        reason: 'a secure generator must not collide over 50 draws');
  });

  test('secure tokens are the requested length', () {
    expect(Entropy.secureToken(bytes: 32).length, 64); // 32 bytes = 64 hex chars
    expect(Entropy.secureToken(bytes: 16).length, 32);
  });

  test('a clock-seeded token is enumerable over a small time window', () {
    const start = 1735689600000; // fixed instant, so the test is deterministic
    final candidates = Entropy.tokensForTimeWindow(startMillis: start);
    final actual = Entropy.predictableToken(seed: start + 3);

    expect(candidates, contains(actual),
        reason: 'guessing the issue time to within 5 ms recovers the token');
    expect(Entropy.bruteForceCost(windowMillis: 1000), 1000,
        reason: 'one second of uncertainty is 1000 guesses, not 2^128');
  });
}
