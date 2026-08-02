// Article 9 — the same request, resolved by a client-side gate and by a
// server-side policy. Flip "biometric returned true" to see the client gate
// approve a transfer the server correctly refuses.

import 'package:flutter/material.dart';
import '../services/trust_decision.dart';

class TrustScreen extends StatefulWidget {
  const TrustScreen({super.key});

  @override
  State<TrustScreen> createState() => _TrustScreenState();
}

class _TrustScreenState extends State<TrustScreen> {
  bool _biometricOk = true;
  bool _serverVerifiedAssertion = false;
  bool _sessionOwnsResource = true;
  bool _clientReportsCompromised = false;
  DeviceTier _tier = DeviceTier.green;
  double _amount = 250;

  TrustRequest get _request => TrustRequest(
        biometricOk: _biometricOk,
        serverVerifiedAssertion: _serverVerifiedAssertion,
        sessionOwnsResource: _sessionOwnsResource,
        clientReportsCompromised: _clientReportsCompromised,
        deviceTier: _tier,
        amountCents: (_amount * 100).round(),
      );

  Color _colorFor(TrustDecision d) => switch (d) {
        TrustDecision.allow => Colors.green,
        TrustDecision.stepUp => Colors.orange,
        TrustDecision.deny => Colors.red,
      };

  Widget _decisionCard(String title, String subtitle, TrustDecision d) {
    final c = _colorFor(d);
    return Card(
      color: c.withValues(alpha: 0.1),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: Text(
          d.name.toUpperCase(),
          style: TextStyle(color: c, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = TrustPolicy.clientGate(_request);
    final server = TrustPolicy.serverPolicy(_request);
    final diverged = client != server;

    return Scaffold(
      appBar: AppBar(title: const Text('Trust decision · Article 9')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _decisionCard('Client gate',
              'if (biometricOk) { transfer(); } — a bool on the attacker\'s device', client),
          _decisionCard('Server policy',
              'ownership + hardware verdict + verified assertion', server),
          if (diverged)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '⚠️ The two disagree. The client would have let this through.',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          const Divider(height: 32),
          SwitchListTile(
            value: _biometricOk,
            onChanged: (v) => setState(() => _biometricOk = v),
            title: const Text('local_auth returned true'),
            subtitle: const Text('Frida can force this — the server never hears about it'),
          ),
          SwitchListTile(
            value: _serverVerifiedAssertion,
            onChanged: (v) => setState(() => _serverVerifiedAssertion = v),
            title: const Text('Server verified a hardware-signed assertion'),
            subtitle: const Text('Keystore/Secure Enclave key signed the server nonce'),
          ),
          SwitchListTile(
            value: _sessionOwnsResource,
            onChanged: (v) => setState(() => _sessionOwnsResource = v),
            title: const Text('Session owns the resource'),
            subtitle: const Text('The IDOR check — curl with someone else\'s id'),
          ),
          SwitchListTile(
            value: _clientReportsCompromised,
            onChanged: (v) => setState(() => _clientReportsCompromised = v),
            title: const Text('Client RASP signal: compromised'),
            subtitle: const Text('Advisory only — degrades trust, never grants it'),
          ),
          ListTile(
            title: const Text('Hardware device tier'),
            subtitle: Wrap(
              spacing: 6,
              children: DeviceTier.values
                  .map((t) => ChoiceChip(
                        label: Text(t.name),
                        selected: _tier == t,
                        onSelected: (_) => setState(() => _tier = t),
                      ))
                  .toList(),
            ),
          ),
          ListTile(
            title: Text('Amount: \$${_amount.toStringAsFixed(0)}'),
            subtitle: Slider(
              value: _amount,
              max: 500,
              divisions: 20,
              label: _amount.toStringAsFixed(0),
              onChanged: (v) => setState(() => _amount = v),
            ),
          ),
        ],
      ),
    );
  }
}
