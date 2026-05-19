import '../flutter_shield.dart';

class FlutterShieldStub extends FlutterShieldPlatform {
  static void registerWith([dynamic registrar]) {
    FlutterShieldPlatform.instance = FlutterShieldStub();
  }

  SecurityCheckResult _notApplicable(VulnerabilityType type) {
    return SecurityCheckResult(
      type: type,
      isVulnerable: false,
      message: 'Not applicable on this platform.',
    );
  }

  @override
  Future<SecurityCheckResult> checkRootedJailbroken() async =>
      _notApplicable(VulnerabilityType.rootedJailbroken);

  @override
  Future<SecurityCheckResult> checkDebuggable() async =>
      _notApplicable(VulnerabilityType.debuggableApp);

  @override
  Future<SecurityCheckResult> checkUsbDebugging() async =>
      _notApplicable(VulnerabilityType.usbDebugging);

  @override
  Future<SecurityCheckResult> checkEmulator() async =>
      _notApplicable(VulnerabilityType.emulatorDetection);

  @override
  Future<SecurityCheckResult> checkMalware() async =>
      _notApplicable(VulnerabilityType.malwareExposure);

  @override
  Future<SecurityCheckResult> checkLocalStorage() async =>
      _notApplicable(VulnerabilityType.insecureLocalStorage);

  @override
  Future<SecurityCheckResult> checkPlaintextData() async =>
      _notApplicable(VulnerabilityType.plaintextData);

  @override
  Future<SecurityCheckResult> checkKeychainKeystore() async =>
      _notApplicable(VulnerabilityType.improperKeychainKeystore);

  @override
  Future<SecurityCheckResult> checkFilePermissions() async =>
      _notApplicable(VulnerabilityType.insecureFilePermissions);

  @override
  Future<SecurityCheckResult> checkExternalStorage() async =>
      _notApplicable(VulnerabilityType.externalStorageSensitiveData);

  @override
  Future<SecurityCheckResult> checkBackupEnabled() async =>
      _notApplicable(VulnerabilityType.backupEnabled);

  @override
  Future<SecurityCheckResult> checkBiometricHandling() async =>
      _notApplicable(VulnerabilityType.weakBiometricHandling);

  @override
  Future<SecurityCheckResult> checkBiometricBypass() async =>
      _notApplicable(VulnerabilityType.biometricBypass);

  @override
  Future<SecurityCheckResult> checkScreenLock() async =>
      _notApplicable(VulnerabilityType.screenLockNotEnforced);

  @override
  Future<SecurityCheckResult> checkScreenshotRestriction() async =>
      _notApplicable(VulnerabilityType.screenshotNotRestricted);

  @override
  Future<SecurityCheckResult> checkScreenRecording() async =>
      _notApplicable(VulnerabilityType.screenRecordingNotRestricted);

  @override
  Future<SecurityCheckResult> checkClipboard() async =>
      _notApplicable(VulnerabilityType.clipboardLeakage);

  @override
  Future<SecurityCheckResult> checkOverlayAttack() async =>
      _notApplicable(VulnerabilityType.overlayAttack);

  @override
  Future<SecurityCheckResult> checkBackgroundDataExposure() async =>
      _notApplicable(VulnerabilityType.backgroundDataExposure);

  @override
  Future<SecurityCheckResult> checkRecentApps() async =>
      _notApplicable(VulnerabilityType.recentAppsExposure);

  @override
  Future<SecurityCheckResult> checkIPC() async =>
      _notApplicable(VulnerabilityType.insecureIPC);

  @override
  Future<SecurityCheckResult> checkIntentHijacking() async =>
      _notApplicable(VulnerabilityType.intentHijacking);

  @override
  Future<SecurityCheckResult> checkBroadcastReceiver() async =>
      _notApplicable(VulnerabilityType.broadcastReceiverExposure);

  @override
  Future<SecurityCheckResult> checkDeepLink() async =>
      _notApplicable(VulnerabilityType.deepLinkHijacking);

  @override
  Future<SecurityCheckResult> checkWebViewDebugging() async =>
      _notApplicable(VulnerabilityType.webViewDebugging);

  @override
  Future<SecurityCheckResult> checkWebViewJavaScript() async =>
      _notApplicable(VulnerabilityType.webViewJavaScriptAbuse);

  @override
  Future<SecurityCheckResult> checkRuntimePermissions() async =>
      _notApplicable(VulnerabilityType.runtimePermissionMissing);

  @override
  Future<SecurityCheckResult> checkAutofill() async =>
      _notApplicable(VulnerabilityType.insecureAutofill);

  @override
  Future<SecurityCheckResult> checkSensorAbuse() async =>
      _notApplicable(VulnerabilityType.sensorAbuse);

  @override
  Future<SecurityCheckResult> checkDeviceTime() async =>
      _notApplicable(VulnerabilityType.trustingDeviceTime);

  @override
  Future<SecurityCheckResult> checkSideChannel() async =>
      _notApplicable(VulnerabilityType.sideChannelAttacks);

  @override
  Future<SecurityCheckResult> checkPlayIntegrity() async =>
      _notApplicable(VulnerabilityType.playIntegrityFailed);

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
      checkPlayIntegrity(),
    ]);

    return SecurityReport(
      results: results,
      timestamp: DateTime.now(),
      totalChecks: results.length,
      vulnerabilitiesFound: results.where((r) => r.isVulnerable).length,
    );
  }
}
