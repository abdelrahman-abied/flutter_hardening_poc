import 'package:flutter/material.dart';
import '../services/security_service.dart';

class RaspScreen extends StatefulWidget {
  const RaspScreen({super.key});
  @override
  State<RaspScreen> createState() => _RaspScreenState();
}

class _RaspScreenState extends State<RaspScreen> {
  SecurityVerdict? _verdict;
  bool _running = false;

  Future<void> _scan() async {
    setState(() => _running = true);
    final v = await SecurityService.scan();
    if (!mounted) return;
    setState(() {
      _verdict = v;
      _running = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _scan();
  }

  ({IconData icon, Color color}) _style(CheckStatus s) => switch (s) {
        CheckStatus.pass => (icon: Icons.check_circle, color: Colors.green),
        CheckStatus.fail => (icon: Icons.error, color: Colors.red),
        CheckStatus.unavailable => (icon: Icons.help_outline, color: Colors.grey),
      };

  @override
  Widget build(BuildContext context) {
    final v = _verdict;
    return Scaffold(
      appBar: AppBar(title: const Text('RASP verdict · Article 1')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _running ? null : _scan,
        icon: const Icon(Icons.refresh),
        label: const Text('Re-scan'),
      ),
      body: v == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: v.anySignal
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      v.anySignal
                          ? '⚠️  Signal detected — server would step-up / degrade'
                          : '✅  No blocking signal',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...v.checks.map((c) {
                  final s = _style(c.status);
                  return ListTile(
                    leading: Icon(s.icon, color: s.color),
                    title: Text(c.name),
                    subtitle: Text(c.detail),
                    trailing: Text(c.status.name),
                  );
                }),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'The POC runs debug-detection and the native FFI scan for '
                    'real. Root/jailbreak and emulator checks are marked '
                    '"unavailable" here — wiring them needs device-only plugins. '
                    'Honest reporting is the point (Article 1, §3.1).',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
    );
  }
}
