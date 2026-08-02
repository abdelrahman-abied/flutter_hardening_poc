// Article 8 — runs the injection against a real SQLite database.

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../services/sql_injection_demo.dart';

class SqlScreen extends StatefulWidget {
  const SqlScreen({super.key});

  @override
  State<SqlScreen> createState() => _SqlScreenState();
}

class _SqlScreenState extends State<SqlScreen> {
  final _controller =
      TextEditingController(text: SqlInjectionDemo.classicPayload);
  Database? _db;
  List<Map<String, Object?>> _vulnerable = const [];
  List<Map<String, Object?>> _safe = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final db = await openDatabase(inMemoryDatabasePath);
      await SqlInjectionDemo.seed(db);
      if (!mounted) return;
      setState(() => _db = db);
      await _run();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'sqflite needs a device/simulator: $e');
    }
  }

  Future<void> _run() async {
    final db = _db;
    if (db == null) return;
    final search = _controller.text;
    final v = await SqlInjectionDemo.vulnerable(db, search);
    final s = await SqlInjectionDemo.safe(db, search);
    if (!mounted) return;
    setState(() {
      _vulnerable = v;
      _safe = s;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _db?.close();
    super.dispose();
  }

  Widget _results(String title, List<Map<String, Object?>> rows, bool leaked) =>
      Card(
        color: leaked
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('${rows.length} row(s)', style: const TextStyle(fontSize: 11)),
              const SizedBox(height: 6),
              ...rows.map((r) => Text(
                    '${r['owner']} · ${r['title']}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: r['owner'] != 'amy' ? Colors.red : null,
                      fontWeight:
                          r['owner'] != 'amy' ? FontWeight.bold : FontWeight.normal,
                    ),
                  )),
              if (leaked)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    "❌ Bob's row leaked — the input became SQL",
                    style: TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final leaked = _vulnerable.any((r) => r['owner'] != 'amy');
    return Scaffold(
      appBar: AppBar(title: const Text('SQL injection · Article 8')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Logged in as amy. The query is scoped to owner = 'amy' — "
            'until the search box rewrites it.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Search notes',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _run(),
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red))
          else ...[
            _results('rawQuery with string interpolation (CWE-89)', _vulnerable,
                leaked),
            const SizedBox(height: 8),
            _results('rawQuery with ? placeholders', _safe, false),
          ],
        ],
      ),
    );
  }
}
