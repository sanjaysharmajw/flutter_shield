import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../flutter_shield.dart';

abstract class FlutterShieldPlatform extends PlatformInterface {
  FlutterShieldPlatform() : super(token: _token);

  static final Object _token = Object();
  static FlutterShieldPlatform _instance = MethodChannelFlutterShield();

  static FlutterShieldPlatform get instance => _instance;

  static set instance(FlutterShieldPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // Device Integrity Checks
  Future<SecurityCheckResult> checkRootedJailbroken();
  Future<SecurityCheckResult> checkDebuggable();
  Future<SecurityCheckResult> checkUsbDebugging();
  Future<SecurityCheckResult> checkEmulator();
  Future<SecurityCheckResult> checkMalware();

  // Storage Security
  Future<SecurityCheckResult> checkLocalStorage();
  Future<SecurityCheckResult> checkPlaintextData();
  Future<SecurityCheckResult> checkKeychainKeystore();
  Future<SecurityCheckResult> checkFilePermissions();
  Future<SecurityCheckResult> checkExternalStorage();
  Future<SecurityCheckResult> checkBackupEnabled();

  // Authentication
  Future<SecurityCheckResult> checkBiometricHandling();
  Future<SecurityCheckResult> checkBiometricBypass();
  Future<SecurityCheckResult> checkScreenLock();

  // UI Security
  Future<SecurityCheckResult> checkScreenshotRestriction();
  Future<SecurityCheckResult> checkScreenRecording();
  Future<SecurityCheckResult> checkClipboard();
  Future<SecurityCheckResult> checkOverlayAttack();
  Future<SecurityCheckResult> checkBackgroundDataExposure();
  Future<SecurityCheckResult> checkRecentApps();

  // Communication
  Future<SecurityCheckResult> checkIPC();
  Future<SecurityCheckResult> checkIntentHijacking();
  Future<SecurityCheckResult> checkBroadcastReceiver();
  Future<SecurityCheckResult> checkDeepLink();

  // WebView
  Future<SecurityCheckResult> checkWebViewDebugging();
  Future<SecurityCheckResult> checkWebViewJavaScript();

  // Permissions & Runtime
  Future<SecurityCheckResult> checkRuntimePermissions();
  Future<SecurityCheckResult> checkAutofill();
  Future<SecurityCheckResult> checkSensorAbuse();

  // Other
  Future<SecurityCheckResult> checkDeviceTime();
  Future<SecurityCheckResult> checkSideChannel();

  // Comprehensive check
  Future<SecurityReport> performFullSecurityCheck();
}
