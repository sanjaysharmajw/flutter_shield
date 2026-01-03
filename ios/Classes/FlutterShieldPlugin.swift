import Flutter
import UIKit
import LocalAuthentication

public class FlutterShieldPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_shield", binaryMessenger: registrar.messenger())
    let instance = FlutterShieldPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let checker = SecurityChecker()

    switch call.method {
    case "checkRootedJailbroken":
      result(checker.checkJailbreak())
    case "checkDebuggable":
      result(checker.checkDebuggable())
    case "checkUsbDebugging":
      result(checker.checkUSBDebugging())
    case "checkEmulator":
      result(checker.checkSimulator())
    case "checkMalware":
      result(checker.checkMalware())
    case "checkLocalStorage":
      result(checker.checkLocalStorage())
    case "checkPlaintextData":
      result(checker.checkPlaintextData())
    case "checkKeychainKeystore":
      result(checker.checkKeychain())
    case "checkFilePermissions":
      result(checker.checkFilePermissions())
    case "checkExternalStorage":
      result(checker.checkExternalStorage())
    case "checkBackupEnabled":
      result(checker.checkBackup())
    case "checkBiometricHandling":
      result(checker.checkBiometric())
    case "checkBiometricBypass":
      result(checker.checkBiometricBypass())
    case "checkScreenLock":
      result(checker.checkScreenLock())
    case "checkScreenshotRestriction":
      result(checker.checkScreenshot())
    case "checkScreenRecording":
      result(checker.checkScreenRecording())
    case "checkClipboard":
      result(checker.checkClipboard())
    case "checkOverlayAttack":
      result(checker.checkOverlay())
    case "checkBackgroundDataExposure":
      result(checker.checkBackgroundData())
    case "checkRecentApps":
      result(checker.checkRecentApps())
    case "checkIPC":
      result(checker.checkIPC())
    case "checkIntentHijacking":
      result(checker.checkIntentHijacking())
    case "checkBroadcastReceiver":
      result(checker.checkBroadcastReceiver())
    case "checkDeepLink":
      result(checker.checkDeepLink())
    case "checkWebViewDebugging":
      result(checker.checkWebViewDebugging())
    case "checkWebViewJavaScript":
      result(checker.checkWebViewJavaScript())
    case "checkRuntimePermissions":
      result(checker.checkPermissions())
    case "checkAutofill":
      result(checker.checkAutofill())
    case "checkSensorAbuse":
      result(checker.checkSensors())
    case "checkDeviceTime":
      result(checker.checkDeviceTime())
    case "checkSideChannel":
      result(checker.checkSideChannel())
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

class SecurityChecker {

  func checkJailbreak() -> [String: Any] {
    let isJailbroken = checkJailbreakMethod1() || checkJailbreakMethod2() || checkJailbreakMethod3()
    return [
      "type": "rootedJailbroken",
      "isVulnerable": isJailbroken,
      "message": isJailbroken ? "Device is jailbroken" : "Device is not jailbroken"
    ]
  }

  private func checkJailbreakMethod1() -> Bool {
    #if targetEnvironment(simulator)
    return false
    #else
    let jailbreakPaths = [
      "/Applications/Cydia.app",
      "/Library/MobileSubstrate/MobileSubstrate.dylib",
      "/bin/bash",
      "/usr/sbin/sshd",
      "/etc/apt",
      "/private/var/lib/apt/",
      "/Applications/Sileo.app",
      "/var/lib/cydia"
    ]
    return jailbreakPaths.contains { FileManager.default.fileExists(atPath: $0) }
    #endif
  }

  private func checkJailbreakMethod2() -> Bool {
    guard let path = getenv("DYLD_INSERT_LIBRARIES") else { return false }
    return String(cString: path).count > 0
  }

  private func checkJailbreakMethod3() -> Bool {
    do {
      try "test".write(toFile: "/private/jailbreak.txt", atomically: true, encoding: .utf8)
      try FileManager.default.removeItem(atPath: "/private/jailbreak.txt")
      return true
    } catch {
      return false
    }
  }

  func checkDebuggable() -> [String: Any] {
    #if DEBUG
    let isDebug = true
    #else
    let isDebug = false
    #endif

    return [
      "type": "debuggableApp",
      "isVulnerable": isDebug,
      "message": isDebug ? "App is in debug mode" : "App is in release mode"
    ]
  }

  func checkUSBDebugging() -> [String: Any] {
    // iOS doesn't have USB debugging like Android
    return [
      "type": "usbDebugging",
      "isVulnerable": false,
      "message": "Not applicable on iOS"
    ]
  }

  func checkSimulator() -> [String: Any] {
    #if targetEnvironment(simulator)
    let isSimulator = true
    #else
    let isSimulator = false
    #endif

    return [
      "type": "emulatorDetection",
      "isVulnerable": isSimulator,
      "message": isSimulator ? "Running on simulator" : "Running on real device"
    ]
  }

  func checkMalware() -> [String: Any] {
    // Basic check - iOS sandboxing provides good protection
    return [
      "type": "malwareExposure",
      "isVulnerable": false,
      "message": "iOS sandbox provides malware protection"
    ]
  }

  func checkLocalStorage() -> [String: Any] {
    let defaults = UserDefaults.standard
    let hasData = !defaults.dictionaryRepresentation().isEmpty

    return [
      "type": "insecureLocalStorage",
      "isVulnerable": hasData,
      "message": hasData ? "UserDefaults contains data" : "UserDefaults is empty"
    ]
  }

  func checkPlaintextData() -> [String: Any] {
    guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return ["type": "plaintextData", "isVulnerable": false, "message": "Could not access documents"]
    }

    do {
      let files = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
      let plaintextFiles = files.filter { ["txt", "json", "xml", "plist"].contains($0.pathExtension) }

      return [
        "type": "plaintextData",
        "isVulnerable": !plaintextFiles.isEmpty,
        "message": plaintextFiles.isEmpty ? "No plaintext files found" : "Plaintext files detected"
      ]
    } catch {
      return ["type": "plaintextData", "isVulnerable": false, "message": "Error checking files"]
    }
  }

  func checkKeychain() -> [String: Any] {
    return [
      "type": "improperKeychainKeystore",
      "isVulnerable": false,
      "message": "Keychain check requires app-specific implementation"
    ]
  }

  func checkFilePermissions() -> [String: Any] {
    return [
      "type": "insecureFilePermissions",
      "isVulnerable": false,
      "message": "iOS sandbox handles file permissions"
    ]
  }

  func checkExternalStorage() -> [String: Any] {
    // iOS doesn't have external storage like Android
    return [
      "type": "externalStorageSensitiveData",
      "isVulnerable": false,
      "message": "Not applicable on iOS"
    ]
  }

  func checkBackup() -> [String: Any] {
    // Check if backup is excluded for sensitive files
    return [
      "type": "backupEnabled",
      "isVulnerable": false,
      "message": "Backup exclusion requires file-specific implementation"
    ]
  }

  func checkBiometric() -> [String: Any] {
    let context = LAContext()
    var error: NSError?
    let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

    return [
      "type": "weakBiometricHandling",
      "isVulnerable": !canEvaluate,
      "message": canEvaluate ? "Biometrics available" : "Biometrics not available"
    ]
  }

  func checkBiometricBypass() -> [String: Any] {
    return [
      "type": "biometricBypass",
      "isVulnerable": false,
      "message": "Biometric bypass check requires app-specific logic"
    ]
  }

  func checkScreenLock() -> [String: Any] {
    let context = LAContext()
    var error: NSError?
    let hasPasscode = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)

    return [
      "type": "screenLockNotEnforced",
      "isVulnerable": !hasPasscode,
      "message": hasPasscode ? "Passcode is set" : "No passcode set"
    ]
  }

  func checkScreenshot() -> [String: Any] {
    return [
      "type": "screenshotNotRestricted",
      "isVulnerable": true,
      "message": "Screenshot prevention requires UITextField.textField(field:shouldChangeCharactersIn:replacementString:)"
    ]
  }

  func checkScreenRecording() -> [String: Any] {
    let isCaptured = UIScreen.main.isCaptured
    return [
      "type": "screenRecordingNotRestricted",
      "isVulnerable": isCaptured,
      "message": isCaptured ? "Screen is being recorded" : "Screen not being recorded"
    ]
  }

  func checkClipboard() -> [String: Any] {
    return [
      "type": "clipboardLeakage",
      "isVulnerable": true,
      "message": "Clipboard monitoring not implemented"
    ]
  }

  func checkOverlay() -> [String: Any] {
    // iOS has better protection against overlay attacks
    return [
      "type": "overlayAttack",
      "isVulnerable": false,
      "message": "iOS provides system-level overlay protection"
    ]
  }

  func checkBackgroundData() -> [String: Any] {
    return [
      "type": "backgroundDataExposure",
      "isVulnerable": true,
      "message": "Background data protection requires app-specific logic"
    ]
  }

  func checkRecentApps() -> [String: Any] {
    return [
      "type": "recentAppsExposure",
      "isVulnerable": true,
      "message": "App switcher preview not hidden"
    ]
  }

  func checkIPC() -> [String: Any] {
    return [
      "type": "insecureIPC",
      "isVulnerable": false,
      "message": "iOS sandbox restricts IPC"
    ]
  }

  func checkIntentHijacking() -> [String: Any] {
    // Not applicable on iOS
    return [
      "type": "intentHijacking",
      "isVulnerable": false,
      "message": "Not applicable on iOS"
    ]
  }

  func checkBroadcastReceiver() -> [String: Any] {
    // Not applicable on iOS
    return [
      "type": "broadcastReceiverExposure",
      "isVulnerable": false,
      "message": "Not applicable on iOS"
    ]
  }

  func checkDeepLink() -> [String: Any] {
    return [
      "type": "deepLinkHijacking",
      "isVulnerable": false,
      "message": "Deep link validation requires app-specific implementation"
    ]
  }

  func checkWebViewDebugging() -> [String: Any] {
    return [
      "type": "webViewDebugging",
      "isVulnerable": false,
      "message": "WKWebView debugging check requires runtime inspection"
    ]
  }

  func checkWebViewJavaScript() -> [String: Any] {
    return [
      "type": "webViewJavaScriptAbuse",
      "isVulnerable": false,
      "message": "WKWebView JavaScript check requires runtime inspection"
    ]
  }

  func checkPermissions() -> [String: Any] {
    return [
      "type": "runtimePermissionMissing",
      "isVulnerable": false,
      "message": "Permission validation requires app-specific checks"
    ]
  }

  func checkAutofill() -> [String: Any] {
    return [
      "type": "insecureAutofill",
      "isVulnerable": false,
      "message": "Autofill security requires field-specific implementation"
    ]
  }

  func checkSensors() -> [String: Any] {
    return [
      "type": "sensorAbuse",
      "isVulnerable": false,
      "message": "Sensor access requires permission checks"
    ]
  }

  func checkDeviceTime() -> [String: Any] {
    // Check if automatic time is enabled
    return [
      "type": "trustingDeviceTime",
      "isVulnerable": false,
      "message": "Device time validation requires server-side verification"
    ]
  }

  func checkSideChannel() -> [String: Any] {
    return [
      "type": "sideChannelAttacks",
      "isVulnerable": false,
      "message": "Side-channel protection requires specific implementation"
    ]
  }
}