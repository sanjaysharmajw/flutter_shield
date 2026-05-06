<div align="center">

<img src="https://github.com/sanjaysharmajw/flutter_shield/blob/main/screenshots/image.jpg?raw=true" alt="Flutter Shield" width="100%" />

# Flutter Shield 🛡️

**A comprehensive device security and vulnerability detection package for Flutter — Android & iOS.**

[![pub package](https://img.shields.io/pub/v/flutter_shield.svg?label=pub&color=00D4AA)](https://pub.dev/packages/flutter_shield)
[![pub points](https://img.shields.io/pub/points/flutter_shield?color=00D4AA)](https://pub.dev/packages/flutter_shield/score)
[![popularity](https://img.shields.io/pub/popularity/flutter_shield?color=00D4AA)](https://pub.dev/packages/flutter_shield/score)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-lightgrey.svg)](https://flutter.dev)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.3.0-02569B.svg?logo=flutter)](https://flutter.dev)

</div>

---

## Overview

**Flutter Shield** gives you a single, unified API to detect 31 security vulnerabilities across Android and iOS — from root/jailbreak detection to WebView misconfigurations. Run a full scan in one call or cherry-pick individual checks for targeted enforcement.

---

## Demo

<div align="center">
<img src="https://github.com/sanjaysharmajw/flutter_shield/blob/main/screenshots/Screen_recording_20260102_220421.gif?raw=true" alt="Flutter Shield Demo" width="280"/>
</div>

---

## Screenshots

<div align="center">

| Home Screen | Scan Results | Quick Check |
|:-----------:|:------------:|:-----------:|
| <img src="https://github.com/sanjaysharmajw/flutter_shield/blob/main/screenshots/Screenshot_20260102_220331.png?raw=true" width="200"/> | <img src="https://github.com/sanjaysharmajw/flutter_shield/blob/main/screenshots/Screenshot_20260102_220344.png?raw=true" width="200"/> | <img src="https://github.com/sanjaysharmajw/flutter_shield/blob/main/screenshots/Screenshot_20260102_220353.png?raw=true" width="200"/> |

| iOS — Home | iOS — Results |
|:----------:|:-------------:|
| <img src="https://github.com/sanjaysharmajw/flutter_shield/blob/main/screenshots/Simulator%20Screenshot%20-%20iPhone%2015%20-%202026-01-02%20at%2022.01.40.png?raw=true" width="220"/> | <img src="https://github.com/sanjaysharmajw/flutter_shield/blob/main/screenshots/Simulator%20Screenshot%20-%20iPhone%2015%20-%202026-01-02%20at%2022.01.46.png?raw=true" width="220"/> |

</div>

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Platform Setup](#platform-setup)
- [Quick Start](#quick-start)
- [Usage](#usage)
  - [Full Security Scan](#full-security-scan)
  - [Individual Checks](#individual-checks)
  - [Handling Results](#handling-results)
  - [Conditional Feature Gating](#conditional-feature-gating)
- [API Reference](#api-reference)
- [Security Categories](#security-categories)
- [Best Practices](#best-practices)
- [Platform Differences](#platform-differences)
- [Limitations](#limitations)
- [Contributing](#contributing)
- [License](#license)

---

## Features

Flutter Shield covers **31 security checks** across 7 categories — all returned as typed, structured results.

| Category | Checks | Description |
|---|:---:|---|
| 🔒 Device Integrity | 5 | Root, jailbreak, emulator, debug, malware |
| 🗄️ Storage Security | 6 | Local storage, plaintext, keychain, file permissions |
| 🔑 Authentication | 3 | Biometrics, bypass, screen lock |
| 🖥️ UI Security | 6 | Screenshot, recording, clipboard, overlay, background |
| 📡 Communication | 4 | IPC, intent hijacking, broadcast receivers, deep links |
| 🌐 WebView | 2 | Debugging, JavaScript interface |
| ⚙️ Permissions & Runtime | 3 | Runtime permissions, autofill, sensor abuse |
| 🔬 Other | 2 | Device time trust, side-channel attacks |

---

## Installation

Add Flutter Shield to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_shield: ^1.1.4
```

Then fetch dependencies:

```bash
flutter pub get
```

---

## Platform Setup

### Android

Ensure your `android/app/build.gradle` targets a compatible API level:

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 21       // Android 5.0+
        targetSdkVersion 34
    }
}
```

### iOS

Set the minimum iOS deployment target in your `ios/Podfile`:

```ruby
platform :ios, '12.0'
```

If your app uses sensor-related checks, add the required usage descriptions to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Required for sensor security checks</string>
<key>NSMicrophoneUsageDescription</key>
<string>Required for sensor security checks</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Required for sensor security checks</string>
```

---

## Quick Start

```dart
import 'package:flutter_shield/flutter_shield.dart';

void main() async {
  final report = await FlutterShield.performFullSecurityCheck();

  if (report.isSecure) {
    print('✅ Device passed all ${report.totalChecks} security checks.');
  } else {
    print('⚠️ ${report.vulnerabilitiesFound} issue(s) found:');
    for (final v in report.vulnerabilities) {
      print('  • ${v.type.name}: ${v.message}');
    }
  }
}
```

---

## Usage

### Full Security Scan

Run all 31 checks concurrently in a single call:

```dart
Future<void> runFullScan() async {
  final report = await FlutterShield.performFullSecurityCheck();

  print('Scan completed at: ${report.timestamp}');
  print('Total checks   : ${report.totalChecks}');
  print('Vulnerabilities: ${report.vulnerabilitiesFound}');
  print('Is secure      : ${report.isSecure}');

  for (final result in report.results) {
    final status = result.isVulnerable ? '❌ FAIL' : '✅ PASS';
    print('$status  ${result.type.name}: ${result.message}');
  }
}
```

### Individual Checks

Run specific checks when you need targeted enforcement:

```dart
// Device integrity
final rootCheck    = await FlutterShield.checkRootedJailbroken();
final debugCheck   = await FlutterShield.checkDebuggable();
final usbCheck     = await FlutterShield.checkUsbDebugging();   // Android
final emulatorCheck = await FlutterShield.checkEmulator();
final malwareCheck = await FlutterShield.checkMalware();

// Storage
final storageCheck  = await FlutterShield.checkLocalStorage();
final plaintextCheck = await FlutterShield.checkPlaintextData();
final keystoreCheck = await FlutterShield.checkKeychainKeystore();

// Authentication
final biometricCheck = await FlutterShield.checkBiometricHandling();
final screenLockCheck = await FlutterShield.checkScreenLock();

// UI
final screenshotCheck = await FlutterShield.checkScreenshotRestriction();
final clipboardCheck  = await FlutterShield.checkClipboard();

// WebView
final webViewDebugCheck = await FlutterShield.checkWebViewDebugging();

if (rootCheck.isVulnerable) {
  print('🚨 Device is rooted/jailbroken: ${rootCheck.message}');
}
```

### Handling Results

Use the structured `SecurityCheckResult` to drive UI or business logic:

```dart
Future<void> handleSecurityCheck(BuildContext context) async {
  final result = await FlutterShield.checkRootedJailbroken();

  switch (result.isVulnerable) {
    case true:
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Security Warning'),
          content: Text(result.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
    case false:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Device integrity check passed')),
      );
  }
}
```

### Conditional Feature Gating

Block sensitive features on compromised devices:

```dart
Future<bool> canAccessSensitiveFeature() async {
  // Run checks in parallel for speed
  final results = await Future.wait([
    FlutterShield.checkRootedJailbroken(),
    FlutterShield.checkDebuggable(),
    FlutterShield.checkEmulator(),
  ]);

  final isCompromised = results.any((r) => r.isVulnerable);
  return !isCompromised;
}

// Usage
Future<void> openPaymentScreen() async {
  if (!await canAccessSensitiveFeature()) {
    // Deny access on compromised devices
    showSecurityWarning();
    return;
  }
  Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen()));
}
```

---

## API Reference

### `FlutterShield`

All methods are static and return `Future<SecurityCheckResult>` unless otherwise noted.

#### Device Integrity

| Method | Description | Platform |
|---|---|:---:|
| `checkRootedJailbroken()` | Detects rooted (Android) or jailbroken (iOS) device using multiple methods | Both |
| `checkDebuggable()` | Checks if the app was built with the debuggable flag | Both |
| `checkUsbDebugging()` | Checks if ADB / USB debugging is currently enabled | Android |
| `checkEmulator()` | Detects Android emulator or iOS Simulator | Both |
| `checkMalware()` | Basic suspicious-app detection | Android |

#### Storage Security

| Method | Description | Platform |
|---|---|:---:|
| `checkLocalStorage()` | Checks for unencrypted SharedPreferences / UserDefaults usage | Both |
| `checkPlaintextData()` | Detects plaintext files (`.txt`, `.json`, `.xml`) in app storage | Both |
| `checkKeychainKeystore()` | Validates Keychain (iOS) / Keystore (Android) usage | Both |
| `checkFilePermissions()` | Checks for files with overly broad permissions | Both |
| `checkExternalStorage()` | Detects sensitive data written to external storage | Android |
| `checkBackupEnabled()` | Checks whether Android backup is enabled for app data | Android |

#### Authentication

| Method | Description | Platform |
|---|---|:---:|
| `checkBiometricHandling()` | Validates biometric authentication availability | Both |
| `checkBiometricBypass()` | Checks for biometric bypass vulnerabilities | Both |
| `checkScreenLock()` | Verifies that a screen lock / PIN is enforced | Both |

#### UI Security

| Method | Description | Platform |
|---|---|:---:|
| `checkScreenshotRestriction()` | Checks if `FLAG_SECURE` (Android) prevents screenshots | Both |
| `checkScreenRecording()` | Detects active screen recording (iOS: `UIScreen.isCaptured`) | Both |
| `checkClipboard()` | Checks clipboard monitoring for sensitive data | Both |
| `checkOverlayAttack()` | Detects tapjacking / overlay attack exposure | Android |
| `checkBackgroundDataExposure()` | Checks for data exposure when app goes to background | Both |
| `checkRecentApps()` | Checks if app switcher preview exposes sensitive screens | Both |

#### Communication

| Method | Description | Platform |
|---|---|:---:|
| `checkIPC()` | Validates inter-process communication security | Both |
| `checkIntentHijacking()` | Checks for exported intent vulnerabilities | Android |
| `checkBroadcastReceiver()` | Checks for exposed broadcast receivers | Android |
| `checkDeepLink()` | Validates deep link / URL scheme security | Both |

#### WebView

| Method | Description | Platform |
|---|---|:---:|
| `checkWebViewDebugging()` | Detects if WebView remote debugging is enabled | Both |
| `checkWebViewJavaScript()` | Checks WebView JavaScript interface security | Both |

#### Permissions & Runtime

| Method | Description | Platform |
|---|---|:---:|
| `checkRuntimePermissions()` | Validates runtime permission handling | Both |
| `checkAutofill()` | Checks autofill security for sensitive fields | Both |
| `checkSensorAbuse()` | Checks for unauthorized camera / microphone / GPS access | Both |

#### Other

| Method | Description | Platform |
|---|---|:---:|
| `checkDeviceTime()` | Checks if device uses automatic network time | Android |
| `checkSideChannel()` | Checks for side-channel attack exposure | Both |

#### Comprehensive Check

```dart
// Returns Future<SecurityReport>
final report = await FlutterShield.performFullSecurityCheck();
```

---

### `SecurityCheckResult`

```dart
class SecurityCheckResult {
  final VulnerabilityType type;        // Which vulnerability was checked
  final bool isVulnerable;            // true = issue found
  final String message;               // Human-readable description
  final Map<String, dynamic>? details; // Optional platform-specific metadata
}
```

### `SecurityReport`

```dart
class SecurityReport {
  final List<SecurityCheckResult> results;  // All 31 check results
  final DateTime timestamp;                 // When the scan ran
  final int totalChecks;                    // Always 31
  final int vulnerabilitiesFound;           // Number of failed checks

  bool get isSecure;                        // true when vulnerabilitiesFound == 0
  List<SecurityCheckResult> get vulnerabilities; // Only failed results
}
```

### `VulnerabilityType` enum

```dart
enum VulnerabilityType {
  // Device Integrity
  rootedJailbroken, debuggableApp, usbDebugging, emulatorDetection, malwareExposure,
  // Storage Security
  insecureLocalStorage, plaintextData, improperKeychainKeystore,
  insecureFilePermissions, externalStorageSensitiveData, backupEnabled,
  // Authentication
  weakBiometricHandling, biometricBypass, screenLockNotEnforced,
  // UI Security
  screenshotNotRestricted, screenRecordingNotRestricted, clipboardLeakage,
  overlayAttack, backgroundDataExposure, recentAppsExposure,
  // Communication
  insecureIPC, intentHijacking, broadcastReceiverExposure, deepLinkHijacking,
  // WebView
  webViewDebugging, webViewJavaScriptAbuse,
  // Permissions & Runtime
  runtimePermissionMissing, insecureAutofill, sensorAbuse,
  // Other
  trustingDeviceTime, sideChannelAttacks,
  unknown,
}
```

---

## Security Categories

```
Flutter Shield — 31 Checks
│
├── 🔒 Device Integrity (5)
│   ├── Root / Jailbreak detection     [multi-method]
│   ├── Debuggable app flag
│   ├── USB debugging status           [Android]
│   ├── Emulator / Simulator
│   └── Malware / suspicious apps      [Android]
│
├── 🗄️ Storage Security (6)
│   ├── Unencrypted SharedPreferences / UserDefaults
│   ├── Plaintext files in app storage
│   ├── Keychain / Keystore validation
│   ├── File permissions (rwx)
│   ├── External storage usage         [Android]
│   └── Backup configuration           [Android]
│
├── 🔑 Authentication (3)
│   ├── Biometric handling
│   ├── Biometric bypass
│   └── Screen lock / PIN enforcement
│
├── 🖥️ UI Security (6)
│   ├── Screenshot restriction (FLAG_SECURE)
│   ├── Screen recording detection
│   ├── Clipboard monitoring
│   ├── Overlay / tapjacking
│   ├── Background data exposure
│   └── Recent apps preview
│
├── 📡 Communication (4)
│   ├── IPC security
│   ├── Intent hijacking               [Android]
│   ├── Broadcast receiver exposure    [Android]
│   └── Deep link hijacking
│
├── 🌐 WebView (2)
│   ├── WebView remote debugging
│   └── JavaScript interface security
│
├── ⚙️ Permissions & Runtime (3)
│   ├── Runtime permission validation
│   ├── Autofill security
│   └── Sensor abuse (Camera/Mic/GPS)
│
└── 🔬 Other (2)
    ├── Device time trust (Auto time)   [Android]
    └── Side-channel attack exposure
```

---

## Best Practices

**1. Check at startup**
```dart
@override
void initState() {
  super.initState();
  _runSecurityCheck();
}
```

**2. Gate sensitive features**
```dart
// Never allow payments or biometric auth on rooted devices
final rootCheck = await FlutterShield.checkRootedJailbroken();
if (rootCheck.isVulnerable) blockSensitiveFeature();
```

**3. Run checks in parallel when you need multiple results**
```dart
final results = await Future.wait([
  FlutterShield.checkRootedJailbroken(),
  FlutterShield.checkDebuggable(),
  FlutterShield.checkEmulator(),
]);
```

**4. Log security events**
```dart
final report = await FlutterShield.performFullSecurityCheck();
if (!report.isSecure) {
  analytics.logEvent('security_issues_found', {
    'count': report.vulnerabilitiesFound,
    'issues': report.vulnerabilities.map((v) => v.type.name).toList(),
  });
}
```

**5. Educate users gracefully**

Rather than silently blocking, show clear explanations so users understand the risk and can take action (e.g., disable USB debugging).

---

## Platform Differences

| Check | Android | iOS |
|---|:---:|:---:|
| Root / Jailbreak | ✅ su binaries, build tags | ✅ Cydia paths, DYLD |
| USB Debugging | ✅ ADB setting | ➖ N/A |
| External Storage | ✅ | ➖ Sandboxed |
| Intent Hijacking | ✅ | ➖ N/A |
| Broadcast Receivers | ✅ | ➖ N/A |
| Backup Enabled | ✅ | ➖ Different model |
| Screen Recording | ✅ Guided | ✅ `UIScreen.isCaptured` |
| Device Time | ✅ Auto-time setting | ➖ Server-side only |
| Overlay Attack | ✅ | ✅ System-protected |

---

## Limitations

Some checks provide **guidance rather than automated enforcement** because they require app-specific knowledge:

- **Keychain / Keystore** — validation requires your encryption implementation
- **WebView** — JavaScript security requires runtime WebView inspection
- **Autofill** — requires field-level `autofillHints` configuration
- **Biometric bypass** — requires app-specific authentication flow analysis
- **Malware detection** — basic package-name matching; not a full antivirus scan

These checks still return structured results so you can integrate them into your own logic.

---

## Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'feat: add my feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

Please follow the existing code style and add tests for new functionality.

---

## Security Disclosure

Found a security vulnerability in Flutter Shield itself?  
Please email **sanjaysharmajw@gmail.com** — do not open a public issue.

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## Disclaimer

Flutter Shield provides detection and reporting mechanisms. It should be **one layer** of a defence-in-depth security strategy — not your only safeguard. Always follow secure coding practices, apply certificate pinning, encrypt sensitive data at rest, and validate inputs at every system boundary.

---

<div align="center">

Made with ❤️ for the Flutter community

[![pub package](https://img.shields.io/pub/v/flutter_shield.svg?label=flutter_shield&color=00D4AA)](https://pub.dev/packages/flutter_shield)

</div>
