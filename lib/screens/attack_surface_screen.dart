// Article 7 — runs the deep-link / WebView allow-list against hostile URLs.

import 'package:flutter/material.dart';
import '../services/link_guard.dart';

class AttackSurfaceScreen extends StatefulWidget {
  const AttackSurfaceScreen({super.key});

  @override
  State<AttackSurfaceScreen> createState() => _AttackSurfaceScreenState();
}

class _AttackSurfaceScreenState extends State<AttackSurfaceScreen> {
  static const _samples = <String, String>{
    'https://help.example.com/faq': 'Legitimate help page',
    'https://example.com/orders': 'Legitimate deep link',
    'https://evil-example.com/faq': 'Suffix trick — passes a naive endsWith()',
    'https://example.com.attacker.tld/faq': 'Subdomain trick',
    'https://example.com@evil.tld/faq': 'Embedded credentials',
    'javascript:AppBridge.postMessage("/settings/delete-account")':
        'Script scheme into a channel-enabled WebView',
    'file:///data/data/com.example/databases/app.db': 'Local file read',
    'https://example.com/reset-password?token=abc123':
        'Credential smuggled in the query string',
    'myapp://reset-password': 'Custom scheme — claimable by any app',
  };

  final _controller = TextEditingController(text: 'https://help.example.com/faq');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _verdictTile(String label, LinkVerdict v) {
    final ok = v.isAllowed;
    return ListTile(
      dense: true,
      leading: Icon(
        ok ? Icons.check_circle : Icons.block,
        color: ok ? Colors.green : Colors.red,
      ),
      title: Text('$label: ${ok ? 'ALLOWED' : 'BLOCKED'}',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(v.explanation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = _controller.text;
    return Scaffold(
      appBar: AppBar(title: const Text('Attack surface · Article 7')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'One chokepoint validates every URL entering the app. Deny by default.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Inbound URL',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _verdictTile('WebView navigation', LinkGuard.checkWebUrl(url)),
                const Divider(height: 1),
                _verdictTile('Deep link', LinkGuard.checkDeepLink(url)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Try a hostile sample:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._samples.entries.map(
            (e) => Card(
              child: ListTile(
                dense: true,
                title: Text(e.key,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                subtitle: Text(e.value),
                trailing: Icon(
                  LinkGuard.checkDeepLink(e.key).isAllowed
                      ? Icons.check_circle
                      : Icons.block,
                  color: LinkGuard.checkDeepLink(e.key).isAllowed
                      ? Colors.green
                      : Colors.red,
                ),
                onTap: () => setState(() => _controller.text = e.key),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
