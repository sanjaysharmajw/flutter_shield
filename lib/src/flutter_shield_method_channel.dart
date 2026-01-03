import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../flutter_shield.dart';


class MethodChannelFlutterShield extends FlutterShieldPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_shield');

  Future<SecurityCheckResult> _invokeCheck(
      String method,
      VulnerabilityType type,
      ) async {
    try {
      final result = await methodChannel.invokeMethod<Map>(method);
      if (result != null) {
        return SecurityCheckResult.fromMap(Map<String, dynamic>.from(result));
      }
    } catch (e) {
      return SecurityCheckResult(
        type: type,
        isVulnerable: false,
        message: 'Check failed: $e',
      );
    }
    return SecurityCheckResult(
      type: type,
      isVulnerable: false,
      message: 'Unknown error',
    );
  }

  @override
  Future<SecurityCheckResult> checkRootedJailbroken() =>
      _invokeCheck('checkRootedJailbroken', VulnerabilityType.rootedJailbroken);

  @override
  Future<SecurityCheckResult> checkDebuggable() =>
      _invokeCheck('checkDebuggable', VulnerabilityType.debuggableApp);

  @override
  Future<SecurityCheckResult> checkUsbDebugging() =>
      _invokeCheck('checkUsbDebugging', VulnerabilityType.usbDebugging);

  @override
  Future<SecurityCheckResult> checkEmulator() =>
      _invokeCheck('checkEmulator', VulnerabilityType.emulatorDetection);

  @override
  Future<SecurityCheckResult> checkMalware() =>
      _invokeCheck('checkMalware', VulnerabilityType.malwareExposure);

  @override
  Future<SecurityCheckResult> checkLocalStorage() =>
      _invokeCheck('checkLocalStorage', VulnerabilityType.insecureLocalStorage);

  @override
  Future<SecurityCheckResult> checkPlaintextData() =>
      _invokeCheck('checkPlaintextData', VulnerabilityType.plaintextData);

  @override
  Future<SecurityCheckResult> checkKeychainKeystore() =>
      _invokeCheck('checkKeychainKeystore', VulnerabilityType.improperKeychainKeystore);

  @override
  Future<SecurityCheckResult> checkFilePermissions() =>
      _invokeCheck('checkFilePermissions', VulnerabilityType.insecureFilePermissions);

  @override
  Future<SecurityCheckResult> checkExternalStorage() =>
      _invokeCheck('checkExternalStorage', VulnerabilityType.externalStorageSensitiveData);

  @override
  Future<SecurityCheckResult> checkBackupEnabled() =>
      _invokeCheck('checkBackupEnabled', VulnerabilityType.backupEnabled);

  @override
  Future<SecurityCheckResult> checkBiometricHandling() =>
      _invokeCheck('checkBiometricHandling', VulnerabilityType.weakBiometricHandling);

  @override
  Future<SecurityCheckResult> checkBiometricBypass() =>
      _invokeCheck('checkBiometricBypass', VulnerabilityType.biometricBypass);

  @override
  Future<SecurityCheckResult> checkScreenLock() =>
      _invokeCheck('checkScreenLock', VulnerabilityType.screenLockNotEnforced);

  @override
  Future<SecurityCheckResult> checkScreenshotRestriction() =>
      _invokeCheck('checkScreenshotRestriction', VulnerabilityType.screenshotNotRestricted);

  @override
  Future<SecurityCheckResult> checkScreenRecording() =>
      _invokeCheck('checkScreenRecording', VulnerabilityType.screenRecordingNotRestricted);

  @override
  Future<SecurityCheckResult> checkClipboard() =>
      _invokeCheck('checkClipboard', VulnerabilityType.clipboardLeakage);

  @override
  Future<SecurityCheckResult> checkOverlayAttack() =>
      _invokeCheck('checkOverlayAttack', VulnerabilityType.overlayAttack);

  @override
  Future<SecurityCheckResult> checkBackgroundDataExposure() =>
      _invokeCheck('checkBackgroundDataExposure', VulnerabilityType.backgroundDataExposure);

  @override
  Future<SecurityCheckResult> checkRecentApps() =>
      _invokeCheck('checkRecentApps', VulnerabilityType.recentAppsExposure);

  @override
  Future<SecurityCheckResult> checkIPC() =>
      _invokeCheck('checkIPC', VulnerabilityType.insecureIPC);

  @override
  Future<SecurityCheckResult> checkIntentHijacking() =>
      _invokeCheck('checkIntentHijacking', VulnerabilityType.intentHijacking);

  @override
  Future<SecurityCheckResult> checkBroadcastReceiver() =>
      _invokeCheck('checkBroadcastReceiver', VulnerabilityType.broadcastReceiverExposure);

  @override
  Future<SecurityCheckResult> checkDeepLink() =>
      _invokeCheck('checkDeepLink', VulnerabilityType.deepLinkHijacking);

  @override
  Future<SecurityCheckResult> checkWebViewDebugging() =>
      _invokeCheck('checkWebViewDebugging', VulnerabilityType.webViewDebugging);

  @override
  Future<SecurityCheckResult> checkWebViewJavaScript() =>
      _invokeCheck('checkWebViewJavaScript', VulnerabilityType.webViewJavaScriptAbuse);

  @override
  Future<SecurityCheckResult> checkRuntimePermissions() =>
      _invokeCheck('checkRuntimePermissions', VulnerabilityType.runtimePermissionMissing);

  @override
  Future<SecurityCheckResult> checkAutofill() =>
      _invokeCheck('checkAutofill', VulnerabilityType.insecureAutofill);

  @override
  Future<SecurityCheckResult> checkSensorAbuse() =>
      _invokeCheck('checkSensorAbuse', VulnerabilityType.sensorAbuse);

  @override
  Future<SecurityCheckResult> checkDeviceTime() =>
      _invokeCheck('checkDeviceTime', VulnerabilityType.trustingDeviceTime);

  @override
  Future<SecurityCheckResult> checkSideChannel() =>
      _invokeCheck('checkSideChannel', VulnerabilityType.sideChannelAttacks);

  @override
  Future<SecurityReport> performFullSecurityCheck() async {
    final results = <SecurityCheckResult>[];

    // Perform all checks
    results.add(await checkRootedJailbroken());
    results.add(await checkDebuggable());
    results.add(await checkUsbDebugging());
    results.add(await checkEmulator());
    results.add(await checkMalware());
    results.add(await checkLocalStorage());
    results.add(await checkPlaintextData());
    results.add(await checkKeychainKeystore());
    results.add(await checkFilePermissions());
    results.add(await checkExternalStorage());
    results.add(await checkBackupEnabled());
    results.add(await checkBiometricHandling());
    results.add(await checkBiometricBypass());
    results.add(await checkScreenLock());
    results.add(await checkScreenshotRestriction());
    results.add(await checkScreenRecording());
    results.add(await checkClipboard());
    results.add(await checkOverlayAttack());
    results.add(await checkBackgroundDataExposure());
    results.add(await checkRecentApps());
    results.add(await checkIPC());
    results.add(await checkIntentHijacking());
    results.add(await checkBroadcastReceiver());
    results.add(await checkDeepLink());
    results.add(await checkWebViewDebugging());
    results.add(await checkWebViewJavaScript());
    results.add(await checkRuntimePermissions());
    results.add(await checkAutofill());
    results.add(await checkSensorAbuse());
    results.add(await checkDeviceTime());
    results.add(await checkSideChannel());

    final vulnerabilities = results.where((r) => r.isVulnerable).length;

    return SecurityReport(
      results: results,
      timestamp: DateTime.now(),
      totalChecks: results.length,
      vulnerabilitiesFound: vulnerabilities,
    );
  }
}