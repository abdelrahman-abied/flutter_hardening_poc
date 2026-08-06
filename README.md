# Flutter Hardening PoC

A runnable proof-of-concept for the **"Flutter Under the Hood: Hardening & High-Speed Architecture"** article series. Every screen demonstrates a technique from the articles with **live, measured, on-screen results** — and the test suite **proves the claims automatically**.

> The point of this repo: instead of asking you to trust the articles, it lets you *run* them.

---

## What each demo proves

| Demo screen | Article | What you see |
|---|---|---|
| **RASP verdict** | 1 | Runs debug-detection + the native FFI anti-tamper scan for real; honestly marks device-only plugin checks as "unavailable" |
| **Encryption envelope** | 2 | Two parties derive the **same AES key via X25519 ECDH without transmitting it**, then exchange an authenticated AES-256-GCM ciphertext — keys, nonce, tag, and decrypted text shown live |
| **Jank: rebuild scope** | 3 | Two tickers side by side; the unscoped one's "build() ×N" badge **climbs every tick**, the scoped one **stays at ×1** |
| **Image memory budget** | 3 | Live calculator: a 4032×3024 photo = **48 MB** decoded; decode to 800px = **~1 MB**; ~25× waste factor |
| **CustomPainter cost** | 4 | Same wave animated with `saveLayer`+blur (offscreen pass) vs. a direct stroke; both wrapped in `RepaintBoundary` |
| **Concurrency & FFI** | 5 | A perpetual spinner **freezes** on the UI-thread run and **stays smooth** on the isolate run; 8 MB moved via `TransferableTypedData` with a **checksum-verified O(1)** transfer |

---

## What the tests prove (headless, no device needed)

```bash
flutter analyze     # static analysis is clean
flutter test        # all suites pass
```

| Test | Proves |
|---|---|
| `test/crypto_test.dart` | ECDH shared secrets match; GCM round-trips; a fresh nonce every time (no reuse) |
| `test/jank_rebuild_test.dart` | **Scoped demo rebuilds the leaf only** (boxes build ×1); unscoped rebuilds the whole subtree (×N) |
| `test/concurrency_test.dart` | Isolate result equals main-thread result; `TransferableTypedData` moves bytes intact |
| `test/image_math_test.dart` | `decodedBytes = w × h × 4`; downscaling shrinks memory; ~25× waste factor |
| `test/golden_test.dart` | Visual-regression baseline (Article 6) |
| `test/widget_test.dart` | App boots and lists every demo |

`leak_tracker` (bundled with `flutter_test`) runs automatically during widget tests and fails the build on an undisposed controller/subscription (Article 3).

---

## Native & CI (Articles 1, 6)

- `android/app/src/main/cpp/anti_tamper.cpp` + `CMakeLists.txt` — the native anti-Frida engine (XOR-obfuscated signatures), compiled into `libanti_tamper.so` and called via `lib/services/native_security_bridge.dart`. **Requires the Android NDK** to build the APK.
- `android/.../MainActivity.kt` — `FLAG_SECURE` (blocks screenshots / recording / app-switcher preview).
- `.github/workflows/ci.yml` — `flutter analyze` + `flutter test` + **OSV-Scanner** supply-chain gate.
- `.github/dependabot.yml` — pub + gradle auto-update PRs.
- `integration_test/perf_test.dart` + `test_driver/perf_driver.dart` + `tool/check_perf_budget.sh` — the performance-regression gate (run on a real device in `--profile`).

---

## Run it

```bash
flutter pub get
flutter run                     # on a device/emulator — try each demo
flutter test                    # prove the claims headlessly
flutter test --update-goldens   # (re)generate golden baselines
```

---

## Audit *your* app — the companion skill

This repo **demonstrates** the techniques on one app. [**flutter-security-audit**](https://github.com/abdelrahman-abied/flutter-security-audit) **applies** them to any Flutter codebase: an [Agent Skill](https://agentskills.io) distilled from the same article series, which walks the 8 defense layers and writes a severity-ranked report where every finding carries a concrete fix and an attack-based way to verify it.

It works with **any agent that reads the open `SKILL.md` standard** — Claude Code, Cursor, Google Antigravity, Codex CLI, Gemini CLI — and degrades gracefully to a plain bash scanner everywhere else.

```bash
# install once, globally (Claude Code — swap the directory for other agents)
git clone https://github.com/abdelrahman-abied/flutter-security-audit \
  ~/.claude/skills/flutter-security-audit

# then just ask your agent: "security-review this Flutter app"
```

No agent at all? `scan.sh` is dependency-free bash — 36 checks, each tagged **OWASP MASVS + CWE**, exiting non-zero on a confirmed Critical/High so it drops straight into CI:

```bash
./scan.sh /path/to/app          # human-readable, severity-ranked
./scan.sh /path/to/app --json   # machine-readable findings
```

Each layer it audits has a counterpart you can read here:

| Skill layer | Where it lives in this PoC |
|---|---|
| **L1** reverse-engineering resistance | `anti_tamper.cpp` (XOR-obfuscated signatures) — note the release `--obfuscate`/`--split-debug-info` flags are *not* wired here, exactly the kind of gap the skill flags |
| **L2** runtime self-protection (RASP) | RASP verdict screen + `lib/services/native_security_bridge.dart` |
| **L3** screen & data-leak protection | `FLAG_SECURE` in `MainActivity.kt`; `lib/widgets/secure_app_wrapper.dart` (lifecycle overlay) |
| **L4** network / transport | *not covered here* — pinning needs a server (see limitations); the skill checks it |
| **L5** key & data custody | `lib/services/secure_envelope.dart` (X25519 + AES-256-GCM), biometric screen |
| **L6** server-side trust | `lib/services/trust_decision.dart` — the client signals, the server decides |
| **L7** supply chain & pipeline | `.github/workflows/ci.yml` OSV-Scanner gate + `.github/dependabot.yml` |
| **L8** platform, IPC & injection | `webview_screen.dart`, `sql_injection_demo.dart`, `link_guard.dart`, `log_redactor.dart`, `jwt_inspect.dart` |

Same framing as this PoC: **client-side controls raise cost and produce signal; the enforced decision lives on your server and in CI.** Neither the demos nor the report should ever imply an app is unbreakable.

---

## Honest limitations (in the spirit of the series)

- **RASP plugin checks** (root/jailbreak, emulator) are stubbed as "unavailable" — wiring `flutter_jailbreak_detection` + `safe_device` needs a real device.
- **The native FFI scan** returns "unavailable" on host/desktop; it loads `libanti_tamper.so` on an Android device build.
- **`FLAG_SECURE` and screen-blur** are only observable on a device.
- **Cert pinning + server attestation** (Articles 1–2) need a server and are out of scope for a self-contained PoC; the article code stands on its own.
- **Golden files** are platform-sensitive — regenerate on your CI's pinned platform.
