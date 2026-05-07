# Changelog

All notable changes to **Flutter Shield** are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

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
