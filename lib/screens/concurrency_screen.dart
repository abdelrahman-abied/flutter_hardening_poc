import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/concurrency.dart';

class ConcurrencyScreen extends StatefulWidget {
  const ConcurrencyScreen({super.key});
  @override
  State<ConcurrencyScreen> createState() => _ConcurrencyScreenState();
}

class _ConcurrencyScreenState extends State<ConcurrencyScreen> {
  // Big enough to visibly freeze the UI on the main-thread path.
  static const int _iterations = 200000000;
  static const int _bufferBytes = 8 * 1024 * 1024; // 8 MB

  String _log = 'Watch the spinner: it FREEZES on the UI-thread run and keeps '
      'spinning on the isolate run.';
  bool _busy = false;

  Future<void> _runMain() async {
    setState(() => _busy = true);
    final r = await computeOnMain(_iterations); // blocks the UI isolate
    if (!mounted) return;
    setState(() {
      _busy = false;
      _log = 'UI thread: ${r.millis} ms  (result ${r.value})\n'
          '→ the spinner stalled while this ran.';
    });
  }

  Future<void> _runIsolate() async {
    setState(() => _busy = true);
    final r = await computeOnIsolate(_iterations); // off the UI isolate
    if (!mounted) return;
    setState(() {
      _busy = false;
      _log = 'Isolate: ${r.millis} ms  (result ${r.value})\n'
          '→ the spinner kept spinning smoothly.';
    });
  }

  Future<void> _runTransfer() async {
    setState(() => _busy = true);
    final big = Uint8List(_bufferBytes);
    for (var i = 0; i < big.length; i += 997) {
      big[i] = i & 0xFF; // sparse fill so the checksum is non-trivial
    }
    final local = checksum(big);
    final sw = Stopwatch()..start();
    final moved = await transferAndChecksum(big); // O(1) ownership move
    sw.stop();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _log = 'TransferableTypedData moved ${_bufferBytes ~/ (1024 * 1024)} MB '
          'in ${sw.elapsedMilliseconds} ms\n'
          'checksum match: ${moved == local ? "✅ yes" : "❌ no"} '
          '($moved vs $local)';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Concurrency & FFI · Article 5')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('A perpetual spinner is the visual proof:'),
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _runMain,
              icon: const Icon(Icons.warning_amber),
              label: const Text('Run 200M-iteration work on UI thread'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _runIsolate,
              icon: const Icon(Icons.bolt),
              label: const Text('Run the same work on an isolate'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _runTransfer,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Zero-copy transfer 8 MB (TransferableTypedData)'),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_log),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
