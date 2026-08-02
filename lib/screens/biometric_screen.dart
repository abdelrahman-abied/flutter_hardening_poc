// Article 9 — local_auth against the CURRENT 3.x API.
//
// This screen exists mainly to PROVE the article's API claim: `AuthenticationOptions`
// was removed in 3.0.0, `stickyAuth` became `persistAcrossBackgrounding`,
// `useErrorDialogs` is gone, and failures arrive as LocalAuthException. If the
// old tutorial snippet still worked, this file would not compile.
//
// The security point stands regardless: `authenticate()` returns a bool computed
// on the attacker's device. It gates the UI, never the transfer.

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../services/trust_decision.dart';

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  final _auth = LocalAuthentication();
  String _status = 'Not attempted';
  bool? _lastResult;
  List<BiometricType> _available = const [];
  bool _supported = false;

  /// Stands in for a Frida hook forcing `authenticate()` to return true.
  /// Clearly labelled: nothing here fakes a real biometric result silently —
  /// it reproduces the attack from Article 1 on a device with no enrolment.
  bool _simulatePatched = false;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  Future<void> _probe() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = canCheck || await _auth.isDeviceSupported();
      final available = await _auth.getAvailableBiometrics();
      if (!mounted) return;
      setState(() {
        _supported = supported;
        _available = available;
        _status = supported
            ? 'Supported. Enrolled: ${available.isEmpty ? "none" : available.map((e) => e.name).join(", ")}'
            : 'No biometric hardware / not enrolled on this device';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Capability probe failed: $e');
    }
  }

  Future<void> _authenticate() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Confirm your transfer',
        // biometricOnly: false keeps the OS passcode fallback, which is
        // stronger than any PIN screen you would build yourself.
        biometricOnly: false,
        // Was `stickyAuth` before local_auth 3.0.0.
        persistAcrossBackgrounding: true,
        sensitiveTransaction: true,
      );
      if (!mounted) return;
      setState(() {
        _lastResult = ok;
        _status = ok ? 'authenticate() returned true' : 'authenticate() returned false';
      });
    } on LocalAuthException catch (e) {
      // Structured, code-based handling — no PlatformException string matching.
      if (!mounted) return;
      setState(() => _status = 'LocalAuthException: ${e.code}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // The same request, decided both ways (Article 9).
    final biometricOk = _simulatePatched || (_lastResult ?? false);
    final request = TrustRequest(
      biometricOk: biometricOk,
      serverVerifiedAssertion: false, // local_auth produces no assertion
      sessionOwnsResource: true,
      amountCents: 50000, // $500
    );
    final showDecision = _simulatePatched || _lastResult != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Biometric gate · Article 9')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Device capability'),
              subtitle: Text(_status),
              trailing: Icon(
                _supported ? Icons.fingerprint : Icons.no_encryption,
                color: _supported ? Colors.green : Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _authenticate,
            icon: const Icon(Icons.fingerprint),
            label: const Text('Authenticate, then transfer \$500'),
          ),
          SwitchListTile(
            value: _simulatePatched,
            onChanged: (v) => setState(() => _simulatePatched = v),
            title: const Text('Simulate a patched client'),
            subtitle: const Text(
                'Frida forcing authenticate() → true, with no fingerprint presented'),
          ),
          const SizedBox(height: 8),
          if (showDecision) ...[
            Card(
              color: Colors.red.withValues(alpha: 0.08),
              child: ListTile(
                title: const Text('Client gate'),
                subtitle: const Text('if (ok) { transfer(); }'),
                trailing: Text(
                  TrustPolicy.clientGate(request).name.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Card(
              color: Colors.green.withValues(alpha: 0.08),
              child: ListTile(
                title: const Text('Server policy'),
                subtitle:
                    const Text('no verified assertion → step up, not allow'),
                trailing: Text(
                  TrustPolicy.serverPolicy(request).name.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'A patched client returns true without any fingerprint, and your '
                'server never learns a biometric check happened. The prompt is a '
                'UX lock; the decision belongs to the server.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
          if (_available.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Enrolled types: ${_available.map((e) => e.name).join(", ")}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}
