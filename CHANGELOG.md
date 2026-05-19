# Changelog

All notable changes to **Flutter Shield** are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.2.0] - 2026-05-19

### Added

- **Magisk Detection — 7-vector root check (`checkRootedJailbroken()`)**
  Previous implementation used only 3 basic checks (`Build.TAGS`, su binary paths, `which su`) which Magisk + MagiskHide/Shamiko bypasses trivially. Root detection now runs 7 independent vectors:
  1. `test-keys` build tag
  2. Standard `su` binary paths (`/sbin/su`, `/system/xbin/su`, etc.)
  3. `which su` command execution
  4. **Magisk-specific paths** — `/data/adb/magisk`, `/data/adb/modules`, `/sbin/.magisk`, `/sbin/.core/mirror`, `/dev/magisk`, etc.
  5. **Root management packages** — Magisk Manager (`com.topjohnwu.magisk`), Magisk Delta (`io.github.huskydg.magisk`), SuperSU, KingRoot, KingoRoot, and 10+ others
  6. **Dangerous system properties** — `ro.debuggable=1`, `ro.secure=0`, `ro.build.selinux=0` via `getprop`
  7. **Writable system partitions** — `/system`, `/system/bin`, `/vendor/bin`, `/sbin`, etc.
  Result message now includes which specific vectors triggered, e.g. `"Device is rooted: Magisk files detected, root management app installed"`.

- **Play Integrity API (`checkPlayIntegrity()`)** — New method that requests a signed integrity token from Google Play. Returns `isVulnerable: false` with the token in `result.details['token']` and nonce in `result.details['nonce']`. Token must be forwarded to your backend and verified via the Google Play Integrity API for a full device/app verdict. Returns `isVulnerable: true` if the token request fails (e.g. no Google Play Services). Android only.

- **Firebase App Check (`checkFirebaseAppCheck()`)** — New method that verifies device and app integrity using Firebase App Check. Uses **Play Integrity** provider on Android and **App Attest / DeviceCheck** on iOS. No custom backend required — Firebase handles server-side verification automatically. Returns `isVulnerable: false` when attestation passes, `true` when it fails. Requires `Firebase.initializeApp()` and `FirebaseAppCheck.instance.activate()` before calling. This is the recommended check for defeating Magisk + Shamiko completely.

- **New `VulnerabilityType` values**
  - `playIntegrityFailed` — Play Integrity token request failed or unavailable
  - `firebaseAppCheckFailed` — Firebase App Check attestation failed

- **New dependencies**
  - `firebase_core: ^3.13.0`
  - `firebase_app_check: ^0.3.2`

### Changed

- **`FlutterShieldPlugin.kt`** — Added `CoroutineScope(SupervisorJob() + Dispatchers.Main)` to handle the async Play Integrity token request without blocking the method channel thread. Scope is cancelled in `onDetachedFromEngine()` to prevent leaks.
- **`android/build.gradle`** — Added `com.google.android.play:integrity:1.4.0`, `kotlinx-coroutines-android:1.7.3`, and `kotlinx-coroutines-play-services:1.7.3` dependencies.
- **`performFullSecurityCheck()`** — Now includes `checkPlayIntegrity()` (33 total checks). `checkFirebaseAppCheck()` is intentionally excluded because it requires Firebase initialization.
- **README** — Updated check count (31 → 33+), added Firebase App Check Setup section, new App Attestation API reference table, updated Security Categories tree and Platform Differences table.

---

## [1.1.10] - 2026-05-12

### Fixed

- **`checkDebuggable()` — Release APK not detected when signed with debug certificate**
  Previously, `checkDebuggable()` only checked the `FLAG_DEBUGGABLE` manifest flag. A release APK built with `flutter build apk --release` has this flag unset (`0`), so it was incorrectly reported as **PASS** even when the APK was signed with the Android debug keystore. Added `isSignedWithDebugKey()` helper that reads the APK's signing certificate via `PackageManager.GET_SIGNING_CERTIFICATES` (API 28+) / `GET_SIGNATURES` (API < 28) and checks whether the certificate subject DN contains `"Android Debug"`. `checkDebuggable()` now returns `isVulnerable: true` if either the debuggable flag **or** the debug signing is detected.

- **`checkLocalStorage()` — False positive on every Flutter app**
  The check flagged the `shared_prefs` directory as insecure if it contained any files at all. Because the Flutter engine and common SDKs (Firebase, Google Play Services) always write their own SharedPreferences files at startup, this caused every Flutter app to report a storage vulnerability regardless of app-level behaviour. The check now ignores known framework-created prefixes (`FlutterSharedPreferences`, `com.google.`, `firebase.`, `io.flutter.`) and only flags app-specific preference files.

- **`checkExternalStorage()` — False positive on every app with a cache directory**
  Previously any file present in the app's external files directory triggered a vulnerability. This produced false positives from harmless media cache or temp files. The check now only flags files with sensitive extensions: `db`, `sqlite`, `sqlite3`, `key`, `pem`, `p12`, `jks`, `json`, `xml`, `txt`.

- **`_invokeCheck()` — Silent failure masked broken checks as secure**
  When a native method channel call threw an exception, the catch block returned `isVulnerable: false`, making a failed or unavailable check indistinguishable from a genuinely secure result. `MissingPluginException` is now handled separately (returns "not supported on this platform") and all other exceptions surface a clear `"Check unavailable: ..."` message so users can distinguish a failed check from a true PASS.

- **`pubspec.yaml` — `dart pub publish` hard-blocked by caret SDK constraint**
  `sdk: ^3.8.1` uses the `^` shorthand which is not allowed for SDK constraints in `pub`. `dart pub publish` was failing with `^ version constraints aren't allowed for SDK constraints`. Changed to `sdk: ">=3.0.0 <4.0.0"`, which also broadens compatibility to all Dart 3.x users instead of requiring 3.8.1+.

- **`FlutterShieldPlugin.kt` — deprecated `getSubjectDN()` replaced with `getSubjectX500Principal()`**
  `isSignedWithDebugKey()` used `cert.subjectDN.name` which is deprecated since Java 16 / Android 12. Replaced with `cert.subjectX500Principal.name`, the current recommended API. Both return the same RFC 2253 DN string so the `"Android Debug"` detection result is identical.

- **`ios/flutter_shield.podspec` — version kept in sync with pubspec**
  Podspec version updated to `1.1.9` to match `pubspec.yaml`, preventing a pub.dev score deduction for version mismatch.

- **iOS Swift Package Manager (SPM) — source migrated to canonical `Sources/` layout**
  `ios/Classes/FlutterShieldPlugin.swift` moved to `ios/Sources/flutter_shield/FlutterShieldPlugin.swift`. `ios/Package.swift` path updated from `"Classes"` to `"Sources/flutter_shield"` and `ios/flutter_shield.podspec` source files updated to `Sources/flutter_shield/**/*.swift`. This matches the canonical SPM directory structure that Flutter's own plugin template generates and that pub.dev's pana tool requires to award the Swift Package Manager support score (resolves the 10/20 → 20/20 platform support deduction).

### Added

- `isSignedWithDebugKey()` private helper in `SecurityChecker` — reads the APK signing certificate and compares the subject DN against the well-known Android debug keystore identity (`CN=Android Debug`). Handles both the modern `SigningInfo` API (Android 9+) and the legacy `signatures` field.

---

## [1.1.6] - 2026-05-07

### Fixed
- **Demo GIF not rendering in README** — Compressed `Screen_recording_20260507_103132.gif` from 38 MB to 7.1 MB (81 % reduction) using resolution downscale (1080×2424 → 320×718), framerate reduction (25 fps → 10 fps), and 128-colour palette with Bayer dithering; file now falls within GitHub's 10 MB inline-display limit

---

## [1.1.5] - 2026-05-07

### Added
- **Multi-platform support** — Web, Windows, Linux, and macOS now declared as supported platforms via a pure-Dart stub (`FlutterShieldStub`); all 31 checks return `isVulnerable: false` with a "Not applicable on this platform." message on unsupported platforms, keeping `performFullSecurityCheck()` safe to call anywhere
- **Swift Package Manager (SPM)** — Added `ios/Package.swift` so the plugin is recognised by Xcode's SPM integration, resolving the partial pub.dev score deduction for missing SPM support
- **pub.dev platform score** — Platform support score improved from 10 / 20 (Android + iOS only) to 20 / 20 (all 6 platforms)

### Fixed
- **`FlutterShieldStub` not found at build time** — Exported `FlutterShieldStub` from the package's main library (`lib/flutter_shield.dart`) so Flutter's generated `dart_plugin_registrant.dart` can resolve the class during kernel compilation
- **Corrupted Kotlin incremental cache** — Cleaned stale build artefacts that caused `Storage corrupted` errors and prevented the example app from launching on Android

### Changed
- **`pubspec.yaml` description** — Updated to reflect the new six-platform scope
- **`pubspec.yaml` platform declarations** — Added `web`, `windows`, `linux`, `macos` entries each with `pluginClass: none`, `dartPluginClass: FlutterShieldStub`, and `fileName: src/flutter_shield_stub.dart`
- **`ios/flutter_shield.podspec`** — Corrected placeholder values: version, summary, description, homepage, and author now match the published package
- **Screenshots** — Replaced all old screenshots and the demo GIF with updated assets; Demo, Home Screen, and Scan Results displayed horizontally in the README

---

## [1.1.4] - 2026-05-06

### Bug Fixes
- **Performance** — `performFullSecurityCheck()` now runs all 31 checks in parallel using `Future.wait()` instead of sequentially, significantly reducing total scan time
- **Type Safety** — `SecurityCheckResult.fromMap()` now properly casts the `details` field using `Map<String, dynamic>.from()`, preventing potential runtime type errors when native code returns nested maps
- **Stale Test** — Kotlin unit test updated to verify the correct `notImplemented()` behavior instead of testing the non-existent `getPlatformVersion` method
- **Analyzer Warning** — Removed unused `platform` variable and its dangling import in `flutter_shield_method_channel_test.dart`
- **Dependencies** — Removed three unused dependencies (`path_provider`, `shared_preferences`, `device_info_plus`) from `pubspec.yaml`, reducing package weight and transitive dependency graph

### Example App — Full UI Redesign
- Dark-themed design system with radial gradient background (`#0A0E1A`)
- Animated shield hero with pulsing glow aura on the home screen
- Radial scan animation with rotating icon during active scan
- Security score ring — animated arc (CustomPainter) that reveals the score from 0 on load
- Dynamic score label: *Well Protected / Moderate Risk / High Risk / Critical Risk*
- Three-column stats row: Passed · Failed · Total
- Results grouped into 7 security categories, each with inline progress bar and issue count
- Expandable category sections with smooth `AnimatedSize` transitions
- Per-check PASS / FAIL badges with tap-to-expand messages
- Six quick-check grid cards on the home screen
- Bottom sheet for quick-check results with status badge and message card
- Slide-in page transition (380 ms, `easeOutCubic`)
- Migrated all `Color.withOpacity()` calls to the modern `Color.withValues(alpha:)` API

---

## [1.1.3] - 2026-01-02

### Changed
- Updated README

---

## [1.1.2] - 2026-01-02

### Initial Release

#### Features
- Complete coverage of 31 security vulnerabilities
- Support for both Android and iOS platforms
- Comprehensive security reporting via `SecurityReport`
- Individual check methods for targeted testing
- Full security scan via `performFullSecurityCheck()`

#### Device Integrity
- Root / Jailbreak detection with three independent methods
- Debuggable app detection
- USB debugging status check (Android)
- Emulator / Simulator detection
- Basic malware exposure detection

#### Storage Security
- Local storage security analysis
- Plaintext data detection
- Keychain / Keystore validation framework
- File permissions checking
- External storage analysis
- Backup configuration checking

#### Authentication
- Biometric handling validation
- Biometric bypass detection
- Screen lock enforcement checking

#### UI Security
- Screenshot restriction checking
- Screen recording detection (active capture check on iOS)
- Clipboard security analysis
- Overlay attack detection framework
- Background data exposure checking
- Recent apps exposure detection

#### Communication
- IPC security analysis
- Intent hijacking detection (Android)
- Broadcast receiver exposure checking (Android)
- Deep link security validation

#### WebView Security
- WebView debugging detection
- JavaScript interface security checking

#### Permissions & Runtime
- Runtime permission validation
- Autofill security checking
- Sensor abuse detection framework

#### Other
- Device time trust validation
- Side-channel attack detection framework

#### Platform Support
- Android: API 21+ (Android 5.0 Lollipop and above)
- iOS: 12.0+
