// Article 3 — rebuild scope.
// Both demos tick at the same rate; the ONLY difference is how the update is
// delivered. The CountingBox widgets are intentionally non-const so we can
// observe rebuilds (a const child would be skipped by canonicalization — which
// is exactly WHY const helps, but here we want to isolate the scoping variable).
// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'package:flutter/material.dart';

/// A "heavy" widget that counts how many times its build() runs and shows it.
/// If it's never rebuilt, the number stays at 1 — that's the proof.
class CountingBox extends StatefulWidget {
  final String label;
  const CountingBox(this.label, {super.key});
  @override
  State<CountingBox> createState() => CountingBoxState();
}

class CountingBoxState extends State<CountingBox> {
  int builds = 0;
  @override
  Widget build(BuildContext context) {
    builds++;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.widgets),
        title: Text(widget.label),
        trailing: Text('build() ×$builds',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

/// ❌ setState at the top rebuilds the whole subtree every tick.
class UnscopedDemo extends StatefulWidget {
  const UnscopedDemo({super.key});
  @override
  State<UnscopedDemo> createState() => _UnscopedDemoState();
}

class _UnscopedDemoState extends State<UnscopedDemo> {
  int _tick = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(milliseconds: 300), (_) => setState(() => _tick++));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Everything below rebuilds on every tick.
    return Column(
      children: [
        Text('tick: $_tick  (setState on whole subtree)'),
        CountingBox('Expensive header'),
        CountingBox('Expensive list item'),
      ],
    );
  }
}

/// ✅ Only the leaf that reads the value rebuilds.
class ScopedDemo extends StatefulWidget {
  const ScopedDemo({super.key});
  @override
  State<ScopedDemo> createState() => _ScopedDemoState();
}

class _ScopedDemoState extends State<ScopedDemo> {
  final _tick = ValueNotifier<int>(0);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(milliseconds: 300), (_) => _tick.value++);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // build() runs ONCE — nothing here calls setState.
    return Column(
      children: [
        ValueListenableBuilder<int>(
          valueListenable: _tick,
          builder: (_, v, _) => Text('tick: $v  (only this rebuilds)'),
        ),
        CountingBox('Expensive header'),
        CountingBox('Expensive list item'),
      ],
    );
  }
}

class JankScreen extends StatelessWidget {
  const JankScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rebuild scope · Article 3')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Both counters tick at the same rate. Watch the “build() ×N” '
              'badges: unscoped climbs with every tick; scoped stays at 1.',
              style: TextStyle(fontSize: 13)),
          SizedBox(height: 16),
          Text('❌ Unscoped (setState at top)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          SizedBox(height: 8),
          UnscopedDemo(),
          Divider(height: 32),
          Text('✅ Scoped (ValueListenableBuilder leaf)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          SizedBox(height: 8),
          ScopedDemo(),
        ],
      ),
    );
  }
}
