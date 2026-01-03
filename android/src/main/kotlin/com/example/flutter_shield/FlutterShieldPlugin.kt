package com.example.flutter_shield

import android.content.Context
import android.content.pm.ApplicationInfo
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

class FlutterShieldPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private lateinit var securityChecker: SecurityChecker

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_shield")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
    securityChecker = SecurityChecker(context)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "checkRootedJailbroken" -> result.success(securityChecker.checkRoot())
      "checkDebuggable" -> result.success(securityChecker.checkDebuggable())
      "checkUsbDebugging" -> result.success(securityChecker.checkUsbDebugging())
      "checkEmulator" -> result.success(securityChecker.checkEmulator())
      "checkMalware" -> result.success(securityChecker.checkMalware())
      "checkLocalStorage" -> result.success(securityChecker.checkLocalStorage())
      "checkPlaintextData" -> result.success(securityChecker.checkPlaintextData())
      "checkKeychainKeystore" -> result.success(securityChecker.checkKeystore())
      "checkFilePermissions" -> result.success(securityChecker.checkFilePermissions())
      "checkExternalStorage" -> result.success(securityChecker.checkExternalStorage())
      "checkBackupEnabled" -> result.success(securityChecker.checkBackup())
      "checkBiometricHandling" -> result.success(securityChecker.checkBiometric())
      "checkBiometricBypass" -> result.success(securityChecker.checkBiometricBypass())
      "checkScreenLock" -> result.success(securityChecker.checkScreenLock())
      "checkScreenshotRestriction" -> result.success(securityChecker.checkScreenshot())
      "checkScreenRecording" -> result.success(securityChecker.checkScreenRecording())
      "checkClipboard" -> result.success(securityChecker.checkClipboard())
      "checkOverlayAttack" -> result.success(securityChecker.checkOverlay())
      "checkBackgroundDataExposure" -> result.success(securityChecker.checkBackgroundData())
      "checkRecentApps" -> result.success(securityChecker.checkRecentApps())
      "checkIPC" -> result.success(securityChecker.checkIPC())
      "checkIntentHijacking" -> result.success(securityChecker.checkIntentHijacking())
      "checkBroadcastReceiver" -> result.success(securityChecker.checkBroadcastReceiver())
      "checkDeepLink" -> result.success(securityChecker.checkDeepLink())
      "checkWebViewDebugging" -> result.success(securityChecker.checkWebViewDebugging())
      "checkWebViewJavaScript" -> result.success(securityChecker.checkWebViewJavaScript())
      "checkRuntimePermissions" -> result.success(securityChecker.checkPermissions())
      "checkAutofill" -> result.success(securityChecker.checkAutofill())
      "checkSensorAbuse" -> result.success(securityChecker.checkSensors())
      "checkDeviceTime" -> result.success(securityChecker.checkDeviceTime())
      "checkSideChannel" -> result.success(securityChecker.checkSideChannel())
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}

class SecurityChecker(private val context: Context) {

  fun checkRoot(): Map<String, Any> {
    val isRooted = checkRootMethod1() || checkRootMethod2() || checkRootMethod3()
    return mapOf(
      "type" to "rootedJailbroken",
      "isVulnerable" to isRooted,
      "message" to if (isRooted) "Device is rooted" else "Device is not rooted"
    )
  }

  private fun checkRootMethod1(): Boolean {
    val buildTags = Build.TAGS
    return buildTags != null && buildTags.contains("test-keys")
  }

  private fun checkRootMethod2(): Boolean {
    val paths = arrayOf(
      "/system/app/Superuser.apk",
      "/sbin/su",
      "/system/bin/su",
      "/system/xbin/su",
      "/data/local/xbin/su",
      "/data/local/bin/su",
      "/system/sd/xbin/su",
      "/system/bin/failsafe/su",
      "/data/local/su",
      "/su/bin/su"
    )
    return paths.any { File(it).exists() }
  }

  private fun checkRootMethod3(): Boolean {
    var process: Process? = null
    return try {
      process = Runtime.getRuntime().exec(arrayOf("/system/xbin/which", "su"))
      val `in` = java.io.BufferedReader(java.io.InputStreamReader(process.inputStream))
      `in`.readLine() != null
    } catch (t: Throwable) {
      false
    } finally {
      process?.destroy()
    }
  }

  fun checkDebuggable(): Map<String, Any> {
    val isDebuggable = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    return mapOf(
      "type" to "debuggableApp",
      "isVulnerable" to isDebuggable,
      "message" to if (isDebuggable) "App is debuggable" else "App is not debuggable"
    )
  }

  fun checkUsbDebugging(): Map<String, Any> {
    val adbEnabled = Settings.Global.getInt(
      context.contentResolver,
      Settings.Global.ADB_ENABLED, 0
    ) == 1
    return mapOf(
      "type" to "usbDebugging",
      "isVulnerable" to adbEnabled,
      "message" to if (adbEnabled) "USB debugging is enabled" else "USB debugging is disabled"
    )
  }

  fun checkEmulator(): Map<String, Any> {
    val isEmulator = (Build.FINGERPRINT.startsWith("generic")
            || Build.FINGERPRINT.startsWith("unknown")
            || Build.MODEL.contains("google_sdk")
            || Build.MODEL.contains("Emulator")
            || Build.MODEL.contains("Android SDK built for x86")
            || Build.MANUFACTURER.contains("Genymotion")
            || (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic"))
            || "google_sdk" == Build.PRODUCT)

    return mapOf(
      "type" to "emulatorDetection",
      "isVulnerable" to isEmulator,
      "message" to if (isEmulator) "Running on emulator" else "Running on real device"
    )
  }

  fun checkMalware(): Map<String, Any> {
    // Basic check - can be extended with more sophisticated detection
    val suspiciousApps = listOf("com.example.malware", "com.suspicious.app")
    val pm = context.packageManager
    val hasMalware = suspiciousApps.any {
      try {
        pm.getPackageInfo(it, 0)
        true
      } catch (e: Exception) {
        false
      }
    }

    return mapOf(
      "type" to "malwareExposure",
      "isVulnerable" to hasMalware,
      "message" to if (hasMalware) "Suspicious apps detected" else "No malware detected"
    )
  }

  fun checkLocalStorage(): Map<String, Any> {
    val sharedPrefsDir = File(context.applicationInfo.dataDir + "/shared_prefs")
    val hasUnencryptedPrefs = sharedPrefsDir.exists() && sharedPrefsDir.listFiles()?.isNotEmpty() == true

    return mapOf(
      "type" to "insecureLocalStorage",
      "isVulnerable" to hasUnencryptedPrefs,
      "message" to if (hasUnencryptedPrefs) "Unencrypted SharedPreferences found" else "Storage appears secure"
    )
  }

  fun checkPlaintextData(): Map<String, Any> {
    // Check for common plaintext storage patterns
    val filesDir = context.filesDir
    val hasPlaintext = filesDir.listFiles()?.any {
      it.extension in listOf("txt", "json", "xml")
    } ?: false

    return mapOf(
      "type" to "plaintextData",
      "isVulnerable" to hasPlaintext,
      "message" to if (hasPlaintext) "Plaintext files detected" else "No obvious plaintext storage"
    )
  }

  fun checkKeystore(): Map<String, Any> {
    // Basic check for keystore usage
    return mapOf(
      "type" to "improperKeychainKeystore",
      "isVulnerable" to false,
      "message" to "Keystore check requires app-specific implementation"
    )
  }

  fun checkFilePermissions(): Map<String, Any> {
    val filesDir = context.filesDir
    val hasInsecurePermissions = filesDir.listFiles()?.any {
      it.canRead() && it.canWrite() && it.canExecute()
    } ?: false

    return mapOf(
      "type" to "insecureFilePermissions",
      "isVulnerable" to hasInsecurePermissions,
      "message" to if (hasInsecurePermissions) "Files with broad permissions found" else "File permissions OK"
    )
  }

  fun checkExternalStorage(): Map<String, Any> {
    val externalFilesDir = context.getExternalFilesDir(null)
    val hasExternalFiles = externalFilesDir?.listFiles()?.isNotEmpty() ?: false

    return mapOf(
      "type" to "externalStorageSensitiveData",
      "isVulnerable" to hasExternalFiles,
      "message" to if (hasExternalFiles) "Files in external storage detected" else "No external storage usage"
    )
  }

  fun checkBackup(): Map<String, Any> {
    val backupEnabled = (context.applicationInfo.flags and ApplicationInfo.FLAG_ALLOW_BACKUP) != 0
    return mapOf(
      "type" to "backupEnabled",
      "isVulnerable" to backupEnabled,
      "message" to if (backupEnabled) "Backup is enabled" else "Backup is disabled"
    )
  }

  fun checkBiometric(): Map<String, Any> {
    return mapOf(
      "type" to "weakBiometricHandling",
      "isVulnerable" to false,
      "message" to "Biometric check requires runtime implementation"
    )
  }

  fun checkBiometricBypass(): Map<String, Any> {
    return mapOf(
      "type" to "biometricBypass",
      "isVulnerable" to false,
      "message" to "Biometric bypass check requires app-specific logic"
    )
  }

  fun checkScreenLock(): Map<String, Any> {
    val km = context.getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
    val isSecure = km.isKeyguardSecure

    return mapOf(
      "type" to "screenLockNotEnforced",
      "isVulnerable" to !isSecure,
      "message" to if (isSecure) "Screen lock is enabled" else "Screen lock not enabled"
    )
  }

  fun checkScreenshot(): Map<String, Any> {
    return mapOf(
      "type" to "screenshotNotRestricted",
      "isVulnerable" to true,
      "message" to "Screenshots not restricted (use FLAG_SECURE in activity)"
    )
  }

  fun checkScreenRecording(): Map<String, Any> {
    return mapOf(
      "type" to "screenRecordingNotRestricted",
      "isVulnerable" to true,
      "message" to "Screen recording not restricted"
    )
  }

  fun checkClipboard(): Map<String, Any> {
    return mapOf(
      "type" to "clipboardLeakage",
      "isVulnerable" to true,
      "message" to "Clipboard not monitored for sensitive data"
    )
  }

  fun checkOverlay(): Map<String, Any> {
    return mapOf(
      "type" to "overlayAttack",
      "isVulnerable" to true,
      "message" to "Overlay detection not implemented"
    )
  }

  fun checkBackgroundData(): Map<String, Any> {
    return mapOf(
      "type" to "backgroundDataExposure",
      "isVulnerable" to true,
      "message" to "Background data exposure check requires app-specific logic"
    )
  }

  fun checkRecentApps(): Map<String, Any> {
    return mapOf(
      "type" to "recentAppsExposure",
      "isVulnerable" to true,
      "message" to "Recent apps exposure not prevented"
    )
  }

  fun checkIPC(): Map<String, Any> {
    return mapOf(
      "type" to "insecureIPC",
      "isVulnerable" to false,
      "message" to "IPC check requires manifest analysis"
    )
  }

  fun checkIntentHijacking(): Map<String, Any> {
    return mapOf(
      "type" to "intentHijacking",
      "isVulnerable" to false,
      "message" to "Intent hijacking check requires manifest analysis"
    )
  }

  fun checkBroadcastReceiver(): Map<String, Any> {
    return mapOf(
      "type" to "broadcastReceiverExposure",
      "isVulnerable" to false,
      "message" to "Broadcast receiver check requires manifest analysis"
    )
  }

  fun checkDeepLink(): Map<String, Any> {
    return mapOf(
      "type" to "deepLinkHijacking",
      "isVulnerable" to false,
      "message" to "Deep link check requires manifest analysis"
    )
  }

  fun checkWebViewDebugging(): Map<String, Any> {
    return mapOf(
      "type" to "webViewDebugging",
      "isVulnerable" to false,
      "message" to "WebView debugging check requires runtime inspection"
    )
  }

  fun checkWebViewJavaScript(): Map<String, Any> {
    return mapOf(
      "type" to "webViewJavaScriptAbuse",
      "isVulnerable" to false,
      "message" to "WebView JavaScript check requires runtime inspection"
    )
  }

  fun checkPermissions(): Map<String, Any> {
    return mapOf(
      "type" to "runtimePermissionMissing",
      "isVulnerable" to false,
      "message" to "Permission validation requires app-specific checks"
    )
  }

  fun checkAutofill(): Map<String, Any> {
    return mapOf(
      "type" to "insecureAutofill",
      "isVulnerable" to false,
      "message" to "Autofill security requires app-specific implementation"
    )
  }

  fun checkSensors(): Map<String, Any> {
    return mapOf(
      "type" to "sensorAbuse",
      "isVulnerable" to false,
      "message" to "Sensor abuse check requires permission analysis"
    )
  }

  fun checkDeviceTime(): Map<String, Any> {
    val autoTime = Settings.Global.getInt(
      context.contentResolver,
      Settings.Global.AUTO_TIME, 0
    ) == 1

    return mapOf(
      "type" to "trustingDeviceTime",
      "isVulnerable" to !autoTime,
      "message" to if (autoTime) "Device uses network time" else "Device time can be manipulated"
    )
  }

  fun checkSideChannel(): Map<String, Any> {
    return mapOf(
      "type" to "sideChannelAttacks",
      "isVulnerable" to false,
      "message" to "Side-channel attack prevention requires specific implementation"
    )
  }
}