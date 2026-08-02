import 'package:flutter/material.dart';
import '../services/secure_envelope.dart';

class CryptoScreen extends StatefulWidget {
  const CryptoScreen({super.key});
  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen> {
  final _controller = TextEditingController(text: 'transfer \$500 to account 12345');
  EnvelopeResult? _result;
  bool _running = false;

  Future<void> _run() async {
    setState(() => _running = true);
    final r = await SecureEnvelope.demoRoundTrip(_controller.text);
    if (!mounted) return;
    setState(() {
      _result = r;
      _running = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _row(String label, String value, {bool mono = true, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value,
              style: TextStyle(
                  fontFamily: mono ? 'monospace' : null, color: color)),
        ],
      ),
    );
  }

  String _short(String hex) =>
      hex.length > 48 ? '${hex.substring(0, 48)}…' : hex;

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Encryption envelope · Article 2')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Plaintext payload',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _running ? null : _run,
            icon: const Icon(Icons.enhanced_encryption),
            label: const Text('Run X25519 → HKDF → AES-GCM exchange'),
          ),
          const SizedBox(height: 16),
          if (r != null) ...[
            Card(
              color: r.roundTripOk && r.sharedSecretsMatch
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.sharedSecretsMatch
                          ? '✅ Both parties derived the SAME key without sending it'
                          : '❌ Shared secrets differ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.roundTripOk
                          ? '✅ Ciphertext decrypted back to the original'
                          : '❌ Round-trip failed',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _row('Client public key (X25519)', _short(r.clientPublicKey)),
            _row('Server public key (X25519)', _short(r.serverPublicKey)),
            _row('Ciphertext (AES-GCM)', _short(r.ciphertextHex)),
            _row('Nonce (96-bit, fresh)', r.nonceHex),
            _row('Auth tag (GCM)', r.macHex),
            _row('Decrypted', r.decrypted, mono: false, color: Colors.green),
          ],
        ],
      ),
    );
  }
}
