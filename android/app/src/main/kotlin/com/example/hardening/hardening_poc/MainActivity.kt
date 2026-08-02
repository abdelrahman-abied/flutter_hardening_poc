package com.example.hardening.hardening_poc

import android.os.Bundle
import android.view.WindowManager.LayoutParams.FLAG_SECURE
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Article 1 — block screenshots, screen recording, and the app-switcher
        // thumbnail across the entire app.
        window.setFlags(FLAG_SECURE, FLAG_SECURE)

        // Article 7 — tapjacking (CWE-1021). Flutter renders into one native
        // view, so the flag goes on the decor view rather than per-widget;
        // there is no Dart-side API (flutter#40422 is still open).
        // Honest scope: Android 12+ (API 31) already blocks full occlusion from
        // other UIDs by default, and this does NOT stop partial occlusion or
        // accessibility abuse. Defence-in-depth for older devices.
        window.decorView.filterTouchesWhenObscured = true
    }
}
