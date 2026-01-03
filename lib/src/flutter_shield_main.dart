import '../flutter_shield.dart';

/// Main Flutter Shield class for security checks
class FlutterShield {
  static FlutterShieldPlatform get _platform => FlutterShieldPlatform.instance;

  // Device Integrity Checks

  /// Check if device is rooted (Android) or jail broken (iOS)
  static Future<SecurityCheckResult> checkRootedJailbroken() =>
      _platform.checkRootedJailbroken();

  /// Check if app is debuggable in production
  static Future<SecurityCheckResult> checkDebuggable() =>
      _platform.checkDebuggable();

  /// Check if USB debugging is enabled (Android)
  static Future<SecurityCheckResult> checkUsbDebugging() =>
      _platform.checkUsbDebugging();

  /// Check if running on emulator/simulator
  static Future<SecurityCheckResult> checkEmulator() =>
      _platform.checkEmulator();

  /// Check for potential malware presence
  static Future<SecurityCheckResult> checkMalware() =>
      _platform.checkMalware();

  // Storage Security

  /// Check for insecure local storage usage
  static Future<SecurityCheckResult> checkLocalStorage() =>
      _platform.checkLocalStorage();

  /// Check for plaintext sensitive data storage
  static Future<SecurityCheckResult> checkPlaintextData() =>
      _platform.checkPlaintextData();

  /// Check keychain/keystore implementation
  static Future<SecurityCheckResult> checkKeychainKeystore() =>
      _platform.checkKeychainKeystore();

  /// Check file permissions security
  static Future<SecurityCheckResult> checkFilePermissions() =>
      _platform.checkFilePermissions();

  /// Check for sensitive data in external storage
  static Future<SecurityCheckResult> checkExternalStorage() =>
      _platform.checkExternalStorage();

  /// Check if backup is enabled for sensitive data
  static Future<SecurityCheckResult> checkBackupEnabled() =>
      _platform.checkBackupEnabled();

  // Authentication

  /// Check biometric authentication implementation
  static Future<SecurityCheckResult> checkBiometricHandling() =>
      _platform.checkBiometricHandling();

  /// Check for biometric bypass vulnerabilities
  static Future<SecurityCheckResult> checkBiometricBypass() =>
      _platform.checkBiometricBypass();

  /// Check if device screen lock is enforced
  static Future<SecurityCheckResult> checkScreenLock() =>
      _platform.checkScreenLock();

  // UI Security

  /// Check if screenshots are restricted
  static Future<SecurityCheckResult> checkScreenshotRestriction() =>
      _platform.checkScreenshotRestriction();

  /// Check if screen recording is restricted
  static Future<SecurityCheckResult> checkScreenRecording() =>
      _platform.checkScreenRecording();

  /// Check for clipboard data leakage
  static Future<SecurityCheckResult> checkClipboard() =>
      _platform.checkClipboard();

  /// Check for overlay attack (tap jacking) vulnerability
  static Future<SecurityCheckResult> checkOverlayAttack() =>
      _platform.checkOverlayAttack();

  /// Check for background data exposure
  static Future<SecurityCheckResult> checkBackgroundDataExposure() =>
      _platform.checkBackgroundDataExposure();

  /// Check recent apps exposure
  static Future<SecurityCheckResult> checkRecentApps() =>
      _platform.checkRecentApps();

  // Communication

  /// Check inter-process communication security
  static Future<SecurityCheckResult> checkIPC() =>
      _platform.checkIPC();

  /// Check for intent hijacking vulnerabilities (Android)
  static Future<SecurityCheckResult> checkIntentHijacking() =>
      _platform.checkIntentHijacking();

  /// Check broadcast receiver exposure (Android)
  static Future<SecurityCheckResult> checkBroadcastReceiver() =>
      _platform.checkBroadcastReceiver();

  /// Check deep link security
  static Future<SecurityCheckResult> checkDeepLink() =>
      _platform.checkDeepLink();

  // WebView

  /// Check if WebView debugging is enabled
  static Future<SecurityCheckResult> checkWebViewDebugging() =>
      _platform.checkWebViewDebugging();

  /// Check WebView JavaScript interface security
  static Future<SecurityCheckResult> checkWebViewJavaScript() =>
      _platform.checkWebViewJavaScript();

  // Permissions & Runtime

  /// Check runtime permission validation
  static Future<SecurityCheckResult> checkRuntimePermissions() =>
      _platform.checkRuntimePermissions();

  /// Check autofill security
  static Future<SecurityCheckResult> checkAutofill() =>
      _platform.checkAutofill();

  /// Check for sensor abuse (camera, mic, GPS)
  static Future<SecurityCheckResult> checkSensorAbuse() =>
      _platform.checkSensorAbuse();

  // Other

  /// Check if app trusts device time/locale
  static Future<SecurityCheckResult> checkDeviceTime() =>
      _platform.checkDeviceTime();

  /// Check for side-channel attack vulnerabilities
  static Future<SecurityCheckResult> checkSideChannel() =>
      _platform.checkSideChannel();

  // Comprehensive Check

  /// Perform full security check covering all vulnerabilities
  static Future<SecurityReport> performFullSecurityCheck() =>
      _platform.performFullSecurityCheck();
}