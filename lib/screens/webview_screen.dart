// Article 7 — a hardened WebView, wired to the same LinkGuard chokepoint the
// deep-link handler uses.
//
// The three rules, in priority order:
//   1. No JavaScript, and no JS channel, unless the page genuinely needs it.
//   2. Allow-list navigation; deny by default.
//   3. Never let external input choose the URL.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../services/link_guard.dart';

/// The demo points at a host that actually resolves, so the allowed case
/// renders a real page instead of a DNS error.
const _demoHosts = {'flutter.dev', 'docs.flutter.dev'};

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  WebViewController? _controller;
  final List<String> _log = [];
  String? _unsupported;

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _note(String line) {
    if (!mounted) return;
    setState(() => _log.insert(0, line));
  }

  Future<void> _build() async {
    // WebView is a mobile-only plugin; the PoC also runs on desktop.
    if (!(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      setState(() => _unsupported =
          'WebView is Android/iOS only — run this demo on a device or simulator.');
      return;
    }

    final controller = WebViewController()
      // 1. JavaScript OFF by default. Note there is deliberately NO
      //    addJavaScriptChannel call here: a channel is an unauthenticated RPC
      //    endpoint for whatever page ends up loaded (CWE-749).
      ..setJavaScriptMode(JavaScriptMode.disabled)
      // 2. Deny-by-default navigation, delegated to the shared allow-list.
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final verdict =
                LinkGuard.checkWebUrl(request.url, hosts: _demoHosts);
            _note(verdict.isAllowed
                ? '✅ allowed  ${request.url}'
                : '⛔ blocked  ${request.url}  — ${verdict.explanation}');
            return verdict.isAllowed
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onWebResourceError: (e) => _note('⚠️ ${e.description}'),
        ),
      );

    // 3. Android: file access defaults to TRUE below API 30, so disable it
    //    explicitly rather than trusting the default (CWE-200).
    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      await platform.setAllowFileAccess(false);
      await platform.setAllowContentAccess(false);
      _note('🔒 Android: allowFileAccess=false, allowContentAccess=false');
    }

    await controller.loadRequest(Uri.parse('https://flutter.dev/'));
    if (!mounted) return;
    setState(() => _controller = controller);
  }

  Future<void> _tryHostile() async {
    // The dangerous case: an externally-supplied URL reaching the WebView.
    //
    // Do NOT rely on the NavigationDelegate here. On Android, onNavigationRequest
    // does not fire for programmatic loadRequest calls (flutter#152168), so the
    // allow-list must be applied at the CALL SITE, before the load happens.
    const hostile = 'https://evil-example.com/steal?x=1';
    final verdict = LinkGuard.checkWebUrl(hostile, hosts: _demoHosts);

    if (!verdict.isAllowed) {
      _note('⛔ refused at the call site  $hostile  — ${verdict.explanation}');
      _note('   (the delegate never fires for loadRequest — flutter#152168)');
      return;
    }
    await _controller?.loadRequest(Uri.parse(hostile));
  }

  @override
  Widget build(BuildContext context) {
    final unsupported = _unsupported;
    return Scaffold(
      appBar: AppBar(title: const Text('Hardened WebView · Article 7')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _controller == null ? null : _tryHostile,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Navigate to a hostile host'),
                  ),
                ),
              ],
            ),
          ),
          if (unsupported != null)
            Expanded(child: Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(unsupported, textAlign: TextAlign.center),
            )))
          else
            Expanded(
              flex: 2,
              child: _controller == null
                  ? const Center(child: CircularProgressIndicator())
                  : WebViewWidget(controller: _controller!),
            ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _log.length,
              itemBuilder: (_, i) => Text(
                _log[i],
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
