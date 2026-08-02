// Article 1 — Screen protection wrapper.
//
// Covers sensitive UI whenever the app leaves the foreground, so the OS
// app-switcher thumbnail is redacted on both platforms. On Android, real
// screenshot BLOCKING comes from FLAG_SECURE in MainActivity.kt; on iOS there
// is no block, only this hide-on-background behaviour.

import 'package:flutter/material.dart';

class SecureAppWrapper extends StatefulWidget {
  final Widget child;
  const SecureAppWrapper({super.key, required this.child});

  @override
  State<SecureAppWrapper> createState() => _SecureAppWrapperState();
}

class _SecureAppWrapperState extends State<SecureAppWrapper> {
  late final AppLifecycleListener _listener;
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onInactive: () => setState(() => _obscured = true),
      onHide: () => setState(() => _obscured = true),
      onResume: () => setState(() => _obscured = false),
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_obscured)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black,
              child: Center(
                child: Icon(Icons.lock_outline, color: Colors.white, size: 48),
              ),
            ),
          ),
      ],
    );
  }
}
