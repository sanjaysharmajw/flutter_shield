![Logo](https://github.com/sanjaysharmajw/flutter_shield/blob/main/screenshots/image.jpg?raw=true)


# Flutter Shield 🛡️

A comprehensive device security and vulnerability detection package for Flutter applications on Android and iOS.

## Features

Flutter Shield provides detection for 30+ security vulnerabilities across multiple categories:

### Device Integrity (5 checks)
- ✅ Rooted/Jailbroken device detection
- ✅ Debuggable app in production
- ✅ USB debugging enabled (Android)
- ✅ Emulator/Simulator detection
- ✅ Device malware exposure

### Storage Security (6 checks)
- ✅ Insecure local storage (SharedPreferences/UserDefaults)
- ✅ Sensitive data in plaintext
- ✅ Improper Keychain/Keystore usage
- ✅ Insecure file permissions
- ✅ External storage for sensitive data
- ✅ Backup enabled for sensitive data

### Authentication (3 checks)
- ✅ Weak biometric authentication handling
- ✅ Biometric bypass via device settings
- ✅ Screen lock/device PIN not enforced

### UI Security (6 checks)
- ✅ Screenshot not restricted
- ✅ Screen recording not restricted
- ✅ Clipboard data leakage
- ✅ Overlay attacks (Tapjacking)
- ✅ Background process data exposure
- ✅ Recent apps exposure

### Communication (4 checks)
- ✅ Insecure IPC
- ✅ Intent hijacking (Android)
- ✅ Broadcast receiver exposure (Android)
- ✅ Deep link hijacking

### WebView (2 checks)
- ✅ WebView debugging enabled
- ✅ WebView JavaScript interface abuse

### Permissions & Runtime (3 checks)
- ✅ Runtime permission validation
- ✅ Insecure autofill usage
- ✅ Sensor abuse (Camera, Mic, GPS)

### Other (2 checks)
- ✅ Trusting device time/locale
- ✅ Side-channel attacks

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_shield: ^1.1.2
```

Then run:

```bash
flutter pub get
```

## Platform Setup

### Android

Add to your `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
    }
}
```

### iOS

Update your `ios/Podfile`:

```ruby
platform :ios, '12.0'
```

Add privacy descriptions to `ios/Runner/Info.plist` if using sensor checks:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to verify security</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to verify security</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need location access to verify security</string>
```

## Usage

### Full Security Check

Run a comprehensive check covering all vulnerabilities:

```dart
import 'package:flutter_shield/flutter_shield.dart';

Future<void> checkSecurity() async {
  final report = await FlutterShield.performFullSecurityCheck();
  
  print('Total checks: ${report.totalChecks}');
  print('Vulnerabilities found: ${report.vulnerabilitiesFound}');
  print('Is secure: ${report.isSecure}');
  
  for (var vulnerability in report.vulnerabilities) {
    print('⚠️ ${vulnerability.type}: ${vulnerability.message}');
  }
}
```

### Individual Checks

Run specific security checks:

```dart
// Check for root/jailbreak
final rootCheck = await FlutterShield.checkRootedJailbroken();
if (rootCheck.isVulnerable) {
  print('Device is rooted/jailbroken!');
}

// Check if app is debuggable
final debugCheck = await FlutterShield.checkDebuggable();
if (debugCheck.isVulnerable) {
  print('App is running in debug mode!');
}

// Check for emulator
final emulatorCheck = await FlutterShield.checkEmulator();
if (emulatorCheck.isVulnerable) {
  print('Running on emulator!');
}

// Check USB debugging (Android)
final usbDebugCheck = await FlutterShield.checkUsbDebugging();

// Check biometric security
final biometricCheck = await FlutterShield.checkBiometricHandling();

// Check screenshot restriction
final screenshotCheck = await FlutterShield.checkScreenshotRestriction();
```

### Handling Results

```dart
Future<void> handleSecurityCheck() async {
  final result = await FlutterShield.checkRootedJailbroken();
  
  if (result.isVulnerable) {
    // Show warning to user
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Security Warning'),
        content: Text(result.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

### Conditional Features

Enable/disable features based on security status:

```dart
Future<bool> shouldEnableSensitiveFeature() async {
  final rootCheck = await FlutterShield.checkRootedJailbroken();
  final debugCheck = await FlutterShield.checkDebuggable();
  
  // Disable sensitive features on compromised devices
  if (rootCheck.isVulnerable || debugCheck.isVulnerable) {
    return false;
  }
  
  return true;
}
```

## API Reference

### FlutterShield Class

All methods are static and return `Future<SecurityCheckResult>` or `Future<SecurityReport>`.

#### Device Integrity
- `checkRootedJailbroken()` - Detect rooted/jailbroken devices
- `checkDebuggable()` - Check if app is debuggable
- `checkUsbDebugging()` - Check USB debugging status (Android)
- `checkEmulator()` - Detect emulator/simulator
- `checkMalware()` - Basic malware detection

#### Storage Security
- `checkLocalStorage()` - Check local storage security
- `checkPlaintextData()` - Detect plaintext data storage
- `checkKeychainKeystore()` - Validate keychain/keystore usage
- `checkFilePermissions()` - Check file permission security
- `checkExternalStorage()` - Check external storage usage
- `checkBackupEnabled()` - Check backup configuration

#### Authentication
- `checkBiometricHandling()` - Validate biometric implementation
- `checkBiometricBypass()` - Check for biometric bypass
- `checkScreenLock()` - Verify screen lock is enabled

#### UI Security
- `checkScreenshotRestriction()` - Check screenshot prevention
- `checkScreenRecording()` - Check screen recording prevention
- `checkClipboard()` - Check clipboard security
- `checkOverlayAttack()` - Detect overlay vulnerabilities
- `checkBackgroundDataExposure()` - Check background data security
- `checkRecentApps()` - Check recent apps exposure

#### Communication
- `checkIPC()` - Check IPC security
- `checkIntentHijacking()` - Check intent security (Android)
- `checkBroadcastReceiver()` - Check broadcast receiver exposure (Android)
- `checkDeepLink()` - Validate deep link security

#### WebView
- `checkWebViewDebugging()` - Check WebView debugging
- `checkWebViewJavaScript()` - Check WebView JavaScript security

#### Permissions & Runtime
- `checkRuntimePermissions()` - Validate runtime permissions
- `checkAutofill()` - Check autofill security
- `checkSensorAbuse()` - Check sensor usage security

#### Other
- `checkDeviceTime()` - Check device time trust
- `checkSideChannel()` - Check side-channel vulnerabilities

### SecurityCheckResult

```dart
class SecurityCheckResult {
  final VulnerabilityType type;
  final bool isVulnerable;
  final String message;
  final Map<String, dynamic>? details;
}
```

### SecurityReport

```dart
class SecurityReport {
  final List<SecurityCheckResult> results;
  final DateTime timestamp;
  final int totalChecks;
  final int vulnerabilitiesFound;
  
  bool get isSecure;
  List<SecurityCheckResult> get vulnerabilities;
}
```

## Best Practices

1. Run security checks at app startup
2. Block sensitive features on compromised devices
3. Log security events for monitoring
4. Educate users about security risks
5. Regularly update the package for new threat detection

## Limitations

Some checks require app-specific implementation:
- Keychain/Keystore validation needs your encryption logic
- WebView checks require runtime WebView inspection
- Some checks provide guidance rather than automated detection

## Platform Differences

- **USB Debugging**: Android only
- **Intent Hijacking**: Android only
- **Broadcast Receivers**: Android only
- **External Storage**: Android only (iOS uses sandboxed storage)
- **Jailbreak Detection**: More reliable on iOS
- **Root Detection**: More reliable on Android

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Security Disclosure

If you discover a security vulnerability, please email sanjaysharmajw@gmail.com

## Disclaimer

This package provides security checks and detection mechanisms, but should not be the only security measure in your application. Always follow secure coding practices and implement defense-in-depth strategies.