// Article 9 — the gate that isn't.
//
// Two policies over the same request. `clientGate` is what most apps ship: a
// boolean computed on the attacker's device. `serverPolicy` is what actually
// decides, using evidence the client cannot manufacture.

enum TrustDecision { allow, stepUp, deny }

/// Hardware-signed device verdict tier (Article 1, Play Integrity / App Attest).
enum DeviceTier { green, yellow, orange, red, unknown }

class TrustRequest {
  /// What `local_auth.authenticate()` returned. Patchable — see the test.
  final bool biometricOk;

  /// Client-side RASP signal (Article 1). Advisory only.
  final bool clientReportsCompromised;

  /// Did the SERVER verify a signature over the nonce it just issued, produced
  /// by a hardware key that required user authentication? This is the evidence.
  final bool serverVerifiedAssertion;

  /// Hardware-signed device integrity verdict, verified server-side.
  final DeviceTier deviceTier;

  /// Does the authenticated session own the resource being acted on? The IDOR
  /// check — the single most commonly missing control in mobile backends.
  final bool sessionOwnsResource;

  final int amountCents;

  const TrustRequest({
    required this.biometricOk,
    required this.serverVerifiedAssertion,
    required this.sessionOwnsResource,
    this.clientReportsCompromised = false,
    this.deviceTier = DeviceTier.unknown,
    this.amountCents = 0,
  });
}

class TrustPolicy {
  /// Money-movement threshold above which a verified assertion is mandatory.
  static const highValueCents = 10000;

  /// THE ANTI-PATTERN. Runs on the attacker's device, decides on a boolean the
  /// attacker controls, and produces no evidence anyone can verify.
  static TrustDecision clientGate(TrustRequest r) =>
      r.biometricOk ? TrustDecision.allow : TrustDecision.deny;

  /// THE BOUNDARY. Runs on the server. Note what it never reads: `biometricOk`.
  /// A claim the client makes about itself is not an input to authorization.
  static TrustDecision serverPolicy(TrustRequest r) {
    // 1. Authorization before authentication strength: does this session even
    //    own the thing it is acting on? No amount of biometrics fixes IDOR.
    if (!r.sessionOwnsResource) return TrustDecision.deny;

    // 2. A hardware verdict the client cannot forge outranks everything it says.
    if (r.deviceTier == DeviceTier.red) return TrustDecision.deny;

    // 3. High-value actions require cryptographic evidence of user presence,
    //    not a self-reported boolean.
    if (r.amountCents >= highValueCents && !r.serverVerifiedAssertion) {
      return TrustDecision.stepUp;
    }

    // 4. Client-side signal degrades trust; it never grants it.
    if (r.clientReportsCompromised ||
        r.deviceTier == DeviceTier.orange ||
        r.deviceTier == DeviceTier.unknown) {
      return TrustDecision.stepUp;
    }

    return TrustDecision.allow;
  }
}
