// Article 8 — the quiet leaks, demonstrated live:
//   1. a seeded Random() reproduces its "token" stream exactly
//   2. a log line is redacted before it can reach a crash breadcrumb
//   3. an unverified JWT is forged with alg:none

import 'package:flutter/material.dart';
import '../services/entropy.dart';
import '../services/jwt_inspect.dart';
import '../services/log_redactor.dart';

class LeaksScreen extends StatefulWidget {
  const LeaksScreen({super.key});

  @override
  State<LeaksScreen> createState() => _LeaksScreenState();
}

class _LeaksScreenState extends State<LeaksScreen> {
  late String _weakA = Entropy.predictableToken();
  late String _weakB = Entropy.predictableToken();
  late String _secureA = Entropy.secureToken();
  late String _secureB = Entropy.secureToken();

  static const _logLine =
      'POST /transfer ok user=amy token=eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoidXNlciJ9.sig '
      'Authorization: Bearer sk_live_abcdef123456 card=4111111111111111';

  late final String _realToken =
      JwtInspect.mintUnsigned({'sub': 'amy', 'role': 'user', 'exp': 1893456000});
  late String _forged = JwtInspect.forgeAlgNone(_realToken, {'role': 'admin'});

  void _regenerate() => setState(() {
        _weakA = Entropy.predictableToken();
        _weakB = Entropy.predictableToken();
        _secureA = Entropy.secureToken();
        _secureB = Entropy.secureToken();
        _forged = JwtInspect.forgeAlgNone(_realToken, {'role': 'admin'});
      });

  Widget _mono(String s) => Text(
        s.length > 64 ? '${s.substring(0, 64)}…' : s,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
      );

  Widget _section(String title, String tag, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(tag, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final weakRepeats = _weakA == _weakB;
    final secureRepeats = _secureA == _secureB;
    final forgedIsAdmin = JwtInspect.clientSideIsAdmin(_forged);

    return Scaffold(
      appBar: AppBar(title: const Text('Quiet leaks · Article 8')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _regenerate,
        icon: const Icon(Icons.refresh),
        label: const Text('Regenerate'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('1 · Random() vs Random.secure()', 'MASVS-CRYPTO · CWE-330', [
            Text(
              weakRepeats
                  ? '❌ Seeded Random() produced the SAME token twice'
                  : '(unexpected) seeded stream differed',
              style: TextStyle(color: weakRepeats ? Colors.red : Colors.grey),
            ),
            _mono(_weakA),
            _mono(_weakB),
            const SizedBox(height: 8),
            Text(
              secureRepeats
                  ? '(astronomically unlikely) secure tokens matched'
                  : '✅ Random.secure() produced two different tokens',
              style: TextStyle(color: secureRepeats ? Colors.red : Colors.green),
            ),
            _mono(_secureA),
            _mono(_secureB),
            const SizedBox(height: 8),
            const Text(
              'A clock-seeded token needs ~1000 guesses per second of '
              'uncertainty — not 2^128.',
              style: TextStyle(fontSize: 11),
            ),
          ]),
          _section('2 · Log redaction', 'MASVS-PRIVACY · CWE-532', [
            const Text('Raw line (would ship to a crash breadcrumb):',
                style: TextStyle(fontSize: 11)),
            _mono(_logLine),
            const SizedBox(height: 8),
            const Text('Redacted:', style: TextStyle(fontSize: 11)),
            Text(
              LogRedactor.redact(_logLine),
              style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 11, color: Colors.green),
            ),
          ]),
          _section('3 · Decoding a JWT is not verifying it',
              'MASVS-AUTH · CWE-347', [
            const Text('Issued token (role: user):', style: TextStyle(fontSize: 11)),
            _mono(_realToken),
            const SizedBox(height: 8),
            const Text('Forged with alg:none (role: admin):',
                style: TextStyle(fontSize: 11)),
            _mono(_forged),
            const SizedBox(height: 8),
            Text(
              forgedIsAdmin
                  ? '❌ A client that reads claims says: ADMIN. It cannot tell '
                      'the difference.'
                  : 'client-side check rejected it',
              style: TextStyle(
                  color: forgedIsAdmin ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold),
            ),
            const Text(
              'The server, with a pinned algorithm, rejects it instantly.',
              style: TextStyle(fontSize: 11),
            ),
          ]),
        ],
      ),
    );
  }
}
