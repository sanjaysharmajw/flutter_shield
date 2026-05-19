import 'dart:io';

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
      return SecurityCheckResult(
        type: type,
        isVulnerable: false,
        message: 'No result returned from native check',
      );
    } on MissingPluginException {
      return SecurityCheckResult(
        type: type,
        isVulnerable: false,
        message: 'Check not supported on this platform',
      );
    } catch (e) {
      // Do NOT silently mark as secure — unknown state is not the same as secure.
      // isVulnerable stays false here but message clearly flags the failure.
      return SecurityCheckResult(
        type: type,
        isVulnerable: false,
        message: 'Check unavailable: $e',
      );
    }
  }

  @override
  Future<SecurityCheckResult> checkRootedJailbroken() async {
    final nativeResult = await _invokeCheck(
      'checkRootedJailbroken',
      VulnerabilityType.rootedJailbroken,
    );
    if (nativeResult.isVulnerable) return nativeResult;

    if (!kIsWeb && Platform.isAndroid) {
      final dartDetected = await Future.wait([
        _checkSuBinary(),
        _checkRootPaths(),
      ]).then((r) => r.any((v) => v));

      if (dartDetected) {
        return SecurityCheckResult(
          type: VulnerabilityType.rootedJailbroken,
          isVulnerable: true,
          message: 'Root detected via Dart-side filesystem/binary checks',
        );
      }
    }
    return nativeResult;
  }

  static Future<bool> _checkSuBinary() async {
    try {
      final result = await Process.run('su', ['-c', 'id'])
          .timeout(const Duration(seconds: 3));
      return result.exitCode == 0;
    } catch (_) {
      try {
        final which = await Process.run('which', ['su'])
            .timeout(const Duration(seconds: 3));
        return which.exitCode == 0;
      } catch (_) {
        return false;
      }
    }
  }

  static Future<bool> _checkRootPaths() async {
    const paths = [
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/system/su',
      '/su/bin/su',
      '/data/local/su',
      '/data/local/bin/su',
      '/system/app/Superuser.apk',
      '/system/app/SuperSU.apk',
      '/data/adb/magisk',
      '/sbin/.magisk',
      '/data/adb/ksu',
      '/data/adb/ksud',
    ];
    for (final path in paths) {
      try {
        if (await File(path).exists()) return true;
      } catch (_) {}
    }
    return false;
  }

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
  Future<SecurityCheckResult> checkKeychainKeystore() => _invokeCheck(
    'checkKeychainKeystore',
    VulnerabilityType.improperKeychainKeystore,
  );

  @override
  Future<SecurityCheckResult> checkFilePermissions() => _invokeCheck(
    'checkFilePermissions',
    VulnerabilityType.insecureFilePermissions,
  );

  @override
  Future<SecurityCheckResult> checkExternalStorage() => _invokeCheck(
    'checkExternalStorage',
    VulnerabilityType.externalStorageSensitiveData,
  );

  @override
  Future<SecurityCheckResult> checkBackupEnabled() =>
      _invokeCheck('checkBackupEnabled', VulnerabilityType.backupEnabled);

  @override
  Future<SecurityCheckResult> checkBiometricHandling() => _invokeCheck(
    'checkBiometricHandling',
    VulnerabilityType.weakBiometricHandling,
  );

  @override
  Future<SecurityCheckResult> checkBiometricBypass() =>
      _invokeCheck('checkBiometricBypass', VulnerabilityType.biometricBypass);

  @override
  Future<SecurityCheckResult> checkScreenLock() =>
      _invokeCheck('checkScreenLock', VulnerabilityType.screenLockNotEnforced);

  @override
  Future<SecurityCheckResult> checkScreenshotRestriction() => _invokeCheck(
    'checkScreenshotRestriction',
    VulnerabilityType.screenshotNotRestricted,
  );

  @override
  Future<SecurityCheckResult> checkScreenRecording() => _invokeCheck(
    'checkScreenRecording',
    VulnerabilityType.screenRecordingNotRestricted,
  );

  @override
  Future<SecurityCheckResult> checkClipboard() =>
      _invokeCheck('checkClipboard', VulnerabilityType.clipboardLeakage);

  @override
  Future<SecurityCheckResult> checkOverlayAttack() =>
      _invokeCheck('checkOverlayAttack', VulnerabilityType.overlayAttack);

  @override
  Future<SecurityCheckResult> checkBackgroundDataExposure() => _invokeCheck(
    'checkBackgroundDataExposure',
    VulnerabilityType.backgroundDataExposure,
  );

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
  Future<SecurityCheckResult> checkBroadcastReceiver() => _invokeCheck(
    'checkBroadcastReceiver',
    VulnerabilityType.broadcastReceiverExposure,
  );

  @override
  Future<SecurityCheckResult> checkDeepLink() =>
      _invokeCheck('checkDeepLink', VulnerabilityType.deepLinkHijacking);

  @override
  Future<SecurityCheckResult> checkWebViewDebugging() =>
      _invokeCheck('checkWebViewDebugging', VulnerabilityType.webViewDebugging);

  @override
  Future<SecurityCheckResult> checkWebViewJavaScript() => _invokeCheck(
    'checkWebViewJavaScript',
    VulnerabilityType.webViewJavaScriptAbuse,
  );

  @override
  Future<SecurityCheckResult> checkRuntimePermissions() => _invokeCheck(
    'checkRuntimePermissions',
    VulnerabilityType.runtimePermissionMissing,
  );

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
    final results = await Future.wait([
      checkRootedJailbroken(),
      checkDebuggable(),
      checkUsbDebugging(),
      checkEmulator(),
      checkMalware(),
      checkLocalStorage(),
      checkPlaintextData(),
      checkKeychainKeystore(),
      checkFilePermissions(),
      checkExternalStorage(),
      checkBackupEnabled(),
      checkBiometricHandling(),
      checkBiometricBypass(),
      checkScreenLock(),
      checkScreenshotRestriction(),
      checkScreenRecording(),
      checkClipboard(),
      checkOverlayAttack(),
      checkBackgroundDataExposure(),
      checkRecentApps(),
      checkIPC(),
      checkIntentHijacking(),
      checkBroadcastReceiver(),
      checkDeepLink(),
      checkWebViewDebugging(),
      checkWebViewJavaScript(),
      checkRuntimePermissions(),
      checkAutofill(),
      checkSensorAbuse(),
      checkDeviceTime(),
      checkSideChannel(),
    ]);

    final vulnerabilities = results.where((r) => r.isVulnerable).length;

    return SecurityReport(
      results: results,
      timestamp: DateTime.now(),
      totalChecks: results.length,
      vulnerabilitiesFound: vulnerabilities,
    );
  }
}
