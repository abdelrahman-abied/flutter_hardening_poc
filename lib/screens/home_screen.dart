import 'package:flutter/material.dart';
import 'rasp_screen.dart';
import 'crypto_screen.dart';
import 'jank_screen.dart';
import 'image_memory_screen.dart';
import 'painter_screen.dart';
import 'concurrency_screen.dart';
import 'attack_surface_screen.dart';
import 'leaks_screen.dart';
import 'trust_screen.dart';
import 'webview_screen.dart';
import 'sql_screen.dart';
import 'biometric_screen.dart';

class _Demo {
  final String title;
  final String article;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
  const _Demo(this.title, this.article, this.subtitle, this.icon, this.builder);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final List<_Demo> _demos = [
    _Demo('RASP verdict', 'Article 1', 'Runtime environment checks + native FFI scan',
        Icons.security, (_) => const RaspScreen()),
    _Demo('Encryption envelope', 'Article 2', 'X25519 → HKDF → AES-256-GCM round-trip',
        Icons.lock, (_) => const CryptoScreen()),
    _Demo('Jank: rebuild scope', 'Article 3', 'Unscoped setState vs ValueListenableBuilder',
        Icons.speed, (_) => const JankScreen()),
    _Demo('Image memory budget', 'Article 3', 'Decoded bytes = w × h × 4 calculator',
        Icons.image, (_) => const ImageMemoryScreen()),
    _Demo('CustomPainter cost', 'Article 4', 'saveLayer+blur vs direct draw',
        Icons.brush, (_) => const PainterScreen()),
    _Demo('Concurrency & FFI', 'Article 5', 'UI-thread vs isolate + zero-copy transfer',
        Icons.memory, (_) => const ConcurrencyScreen()),
    _Demo('Attack surface', 'Article 7', 'Deep-link & WebView allow-list vs hostile URLs',
        Icons.link_off, (_) => const AttackSurfaceScreen()),
    _Demo('Hardened WebView', 'Article 7', 'JS off, deny-by-default nav, no file access',
        Icons.public_off, (_) => const WebViewScreen()),
    _Demo('Quiet leaks', 'Article 8', 'Weak Random, log redaction, forged JWT',
        Icons.visibility_off, (_) => const LeaksScreen()),
    _Demo('SQL injection', 'Article 8', 'Interpolated vs parameterized, on a real DB',
        Icons.storage, (_) => const SqlScreen()),
    _Demo('Trust decision', 'Article 9', 'Client gate vs server policy on the same request',
        Icons.gavel, (_) => const TrustScreen()),
    _Demo('Biometric gate', 'Article 9', 'local_auth 3.x API — a bool is not authorization',
        Icons.fingerprint, (_) => const BiometricScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Hardening PoC'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(28),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Live proof for the "Under the Hood" series',
                style: TextStyle(fontSize: 12)),
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _demos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final d = _demos[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(d.icon)),
              title: Text(d.title),
              subtitle: Text('${d.article} · ${d.subtitle}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: d.builder)),
            ),
          );
        },
      ),
    );
  }
}
