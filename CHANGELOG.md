# Changelog

All notable changes to **Flutter Shield** are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.2.2] - 2026-05-20

### Fixed

- **WASM compatibility — `dart:io` unconditional import**
  `flutter_shield_method_channel.dart` imported `dart:io` unconditionally, making the package incompatible with WASM/web runtimes. Changed to a conditional import (`import 'dart:io' if (dart.library.js_interop) 'dart_io_stub.dart'`) so native platforms use `dart:io` and WASM/web get a no-op stub. All call sites were already guarded by `!kIsWeb && defaultTargetPlatform == TargetPlatform.android`, so behaviour on all platforms is unchanged. `Platform.isAndroid` replaced with `defaultTargetPlatform == TargetPlatform.android` (from `flutter/foundation.dart`) to eliminate the last `dart:io`-only API reference.

- **Swift Package Manager (SPM) — wrong directory structure**
  pub.dev pana expected `ios/flutter_shield/Package.swift` but the package had `ios/Package.swift`. Restructured the iOS native sources to the canonical Flutter SPM layout: `ios/flutter_shield/Package.swift` with sources at `ios/flutter_shield/Sources/flutter_shield/FlutterShieldPlugin.swift`. Updated `ios/flutter_shield.podspec` source path to `flutter_shield/Sources/flutter_shield/**/*.swift` to match.

- **podspec description** — removed stale Firebase/33-check reference; updated to reflect 31 checks and current detection scope.

---

## [1.2.1] - 2026-05-19

### Added

- **Root detection — 3 new native vectors (total: 10 native + 2 Dart = 12 vectors)**

  - **SELinux permissive check** — runs `getenforce`; if the result is `Permissive`, root is almost certain. Magisk on older kernels disables SELinux enforcement and this survives all path-hiding techniques.
  - **Magisk daemon Unix socket** — reads `/proc/net/unix` for abstract sockets `@magisk_service` or `@ksu_`. The Magisk daemon always registers this socket; it is a kernel-level record and cannot be hidden by Magisk Hide or Zygisk.
  - **Zygisk process memory maps** — reads `/proc/self/maps` for `zygisk` or `/data/adb/modules`. Zygisk injects a native library into every process at startup; its path appears in the memory map regardless of filesystem-level hiding.

- **KernelSU & APatch detection**
  - Added KernelSU paths: `/data/adb/ksu`, `/data/adb/ksud`, `/data/adb/ksu/bin/ksud`
  - Added APatch paths: `/data/adb/ap`, `/data/adb/apatch`
  - Added KernelSU Manager package: `me.weishu.kernelsu`
  - Added APatch Manager package: `me.bmax.apatch`
  - Added `ro.build.type=userdebug` and `ro.build.type=eng` to dangerous props check
  - Detection label updated to `"Magisk/KSU/APatch files detected"` to reflect broader coverage

- **Dart-layer root check (Layer 2)** — `_checkSuBinary()` and `_checkRootPaths()` added to `MethodChannelFlutterShield.checkRootedJailbroken()`. These run after the native check and provide an independent Dart-side verification using `dart:io` `Process` and `File` APIs. If native checks are bypassed, Dart-layer checks still run.

### Fixed

- **`checkSuCommand()` — hardcoded `/system/xbin/which` path (Kotlin)**
  The `which` binary is at `/system/bin/which` on most Android devices, not `/system/xbin/which`. The check was silently failing on the majority of real devices. Now tries `/system/bin/which`, `/system/xbin/which`, and plain `which` in order.

- **`checkSuCommand()` — stderr not consumed, causing deadlock (Kotlin)**
  `Runtime.getRuntime().exec()` creates a process with a bounded stderr pipe. If stderr fills up and is never read, the child process blocks writing to it, and the parent (our check) blocks waiting for stdout. This caused a silent hang on some devices. Fixed by calling `process.errorStream.close()` immediately after exec.

- **`checkSuCommand()` — zombie processes from `destroy()` without `waitFor()` (Kotlin)**
  Calling `process.destroy()` without first calling `process.waitFor()` leaves a zombie process entry in the kernel process table. Fixed by calling `waitFor()` before `destroy()` in all exec-based checks.

- **`checkDangerousProps()` — same stderr + zombie process bugs (Kotlin)**
  Applied the same `errorStream.close()` + `waitFor()` fix to the `getprop` process in `checkDangerousProps()`.

- **`process.waitFor()` without timeout — indefinite hang on 3 exec-based checks (Kotlin)**
  `checkSuCommand()`, `checkDangerousProps()`, and `checkSeLinuxPermissive()` all called `process.waitFor()` with no timeout. If the spawned process hangs (e.g. `su` blocked on an SELinux prompt, or `getprop` stalled), the method channel call would block the main thread indefinitely. Fixed by replacing all three with `process.waitFor(3, java.util.concurrent.TimeUnit.SECONDS)`.

- **`checkDangerousProps()` — `ro.build.type=eng` not detected (Kotlin)**
  The check only matched `"userdebug"` for `ro.build.type`. Engineering (`"eng"`) builds are equally insecure — `ro.debuggable` is also `1` and `ro.secure` is `0` on engineering builds. Changed the props definition from `Map<String, String>` to `List<Pair<String, Set<String>>>` so each property matches against a set of dangerous values. `ro.build.type` now flags both `"userdebug"` and `"eng"`.

- **`checkExternalStorage()` — `walkTopDown()` throws `SecurityException` on restricted storage (Kotlin)**
  External storage traversal via `walkTopDown()` can throw `SecurityException` or `IOException` when the storage is unmounted or the app's permission has been revoked at runtime. The traversal was not wrapped in a try-catch, causing an unhandled exception that crashed the entire check. Fixed by wrapping in `try { ... } catch (_: Exception) { false }`.

- **`checkPermissions()` — deprecated `PROCESS_OUTGOING_CALLS` constant (Kotlin)**
  The check referenced `android.Manifest.permission.PROCESS_OUTGOING_CALLS`, which was deprecated in API 29. Replaced with the equivalent string literal `"android.permission.PROCESS_OUTGOING_CALLS"` — stable, no deprecation warning, and semantically identical for manifest-inspection purposes.

- **iOS `checkLocalStorage()` — guaranteed false positive on every Flutter app (Swift)**
  `UserDefaults.standard.dictionaryRepresentation()` is never empty on a running Flutter app — the Flutter engine writes its own keys (`flutter.*`) at startup, before any app code runs. The check compared against an empty dictionary and therefore always returned `isVulnerable: true`. Fixed by filtering out well-known framework key prefixes (`flutter.`, `com.apple.`, `NS`, `Apple`, `UIKit`, `firebase.`, `io.flutter.`) before checking for app-specific keys.

- **iOS `checkClipboard()` — hardcoded `isVulnerable: true` always (Swift)**
  The implementation was an unfinished stub that unconditionally returned `isVulnerable: true` with the message "Clipboard monitoring not implemented", regardless of clipboard state. On iOS 14+, accessing `UIPasteboard.general.string` without the user having placed the content there triggers a system notification banner — inappropriate for a background security check. Replaced with a non-intrusive `UIPasteboard.general.hasStrings` / `hasURLs` occupancy check (no banner, no content read) that returns `isVulnerable: false` with an advisory message.

- **Example app — stale version badge and incorrect check count**
  The home screen version pill displayed `v1.2.0` (one version behind). The scanning overlay text read "Running 33 security checks" (incorrect — the package runs 31 checks). Both corrected to reflect actual values.

### Removed

- **Firebase App Check integration** — `checkFirebaseAppCheck()` method, `firebase_core` and `firebase_app_check` dependencies, and the Firebase App Check Setup section have been removed. The integration introduced mandatory Firebase project setup as a side-effect for all users of the package, even those not using App Check. Root detection now covers the same threat surface via the 12-vector native+Dart approach.
- **Play Integrity API integration** — `checkPlayIntegrity()` method and its Kotlin implementation removed. Play Integrity requires a server-side verification step that cannot be bundled into a client library; including an unverified token check was misleading about the actual security guarantee.
- **`VulnerabilityType.playIntegrityFailed`** and **`VulnerabilityType.firebaseAppCheckFailed`** enum values removed.
- **`kotlinx-coroutines-android`**, **`kotlinx-coroutines-play-services`**, and **`com.google.android.play:integrity`** dependencies removed from `android/build.gradle`.

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
