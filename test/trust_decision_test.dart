// Article 9 — proves the client gate and the server policy disagree exactly
// where it matters, and that the server never reads the client's boolean.

import 'package:flutter_test/flutter_test.dart';
import 'package:hardening_poc/services/trust_decision.dart';

void main() {
  TrustRequest req({
    bool biometricOk = true,
    bool serverVerifiedAssertion = true,
    bool sessionOwnsResource = true,
    bool clientReportsCompromised = false,
    DeviceTier tier = DeviceTier.green,
    int amountCents = 250,
  }) =>
      TrustRequest(
        biometricOk: biometricOk,
        serverVerifiedAssertion: serverVerifiedAssertion,
        sessionOwnsResource: sessionOwnsResource,
        clientReportsCompromised: clientReportsCompromised,
        deviceTier: tier,
        amountCents: amountCents,
      );

  test('THE ATTACK: a patched biometric boolean fools the client gate', () {
    // Frida forced `true`; no fingerprint was ever presented. A $500 transfer.
    final patched = req(
      biometricOk: true,
      serverVerifiedAssertion: false,
      amountCents: 50000,
    );

    expect(TrustPolicy.clientGate(patched), TrustDecision.allow,
        reason: 'the client gate has nothing to go on but the patched boolean');
    expect(TrustPolicy.serverPolicy(patched), TrustDecision.stepUp,
        reason: 'the server saw no verifiable evidence of user presence');
  });

  test('the two policies agree on low-value, fully-attested traffic', () {
    // The honest note: the server is not stricter everywhere. It is stricter
    // exactly where the money is.
    final benign = req(amountCents: 250);
    expect(TrustPolicy.clientGate(benign), TrustDecision.allow);
    expect(TrustPolicy.serverPolicy(benign), TrustDecision.allow);
  });

  test('the server policy ignores biometricOk entirely', () {
    final withBio = req(biometricOk: true);
    final withoutBio = req(biometricOk: false);

    expect(TrustPolicy.serverPolicy(withBio),
        TrustPolicy.serverPolicy(withoutBio),
        reason: 'a claim the client makes about itself is not an authz input');
  });

  test('IDOR outranks every authentication signal', () {
    final notOwner = req(sessionOwnsResource: false, biometricOk: true);
    expect(TrustPolicy.serverPolicy(notOwner), TrustDecision.deny,
        reason: 'no amount of biometrics fixes acting on someone else\'s data');
  });

  test('a hardware RED verdict denies regardless of what the client says', () {
    expect(TrustPolicy.serverPolicy(req(tier: DeviceTier.red)),
        TrustDecision.deny);
  });

  test('high-value transfers require a verified assertion, else step up', () {
    expect(
      TrustPolicy.serverPolicy(req(amountCents: 50000, serverVerifiedAssertion: false)),
      TrustDecision.stepUp,
    );
    expect(
      TrustPolicy.serverPolicy(req(amountCents: 50000, serverVerifiedAssertion: true)),
      TrustDecision.allow,
    );
  });

  test('client-side signal degrades trust but never grants it', () {
    expect(TrustPolicy.serverPolicy(req(clientReportsCompromised: true)),
        TrustDecision.stepUp);
    expect(TrustPolicy.serverPolicy(req(tier: DeviceTier.unknown)),
        TrustDecision.stepUp);
  });

  test('the clean, attested, low-value case is allowed', () {
    expect(TrustPolicy.serverPolicy(req()), TrustDecision.allow);
  });
}
