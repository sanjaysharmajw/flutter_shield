package com.example.flutter_shield

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.util.Base64
import androidx.annotation.NonNull
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import java.io.ByteArrayInputStream
import java.io.File
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.util.UUID

class FlutterShieldPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private lateinit var securityChecker: SecurityChecker
  private val pluginScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

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
      "checkPlayIntegrity" -> {
        pluginScope.launch {
          val checkResult = withContext(Dispatchers.IO) {
            securityChecker.checkPlayIntegrity()
          }
          result.success(checkResult)
        }
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    pluginScope.cancel()
  }
}

class SecurityChecker(private val context: Context) {

  fun checkRoot(): Map<String, Any> {
    val detectedVectors = mutableListOf<String>()

    if (checkTestKeys()) detectedVectors.add("test-keys build")
    if (checkSuPaths()) detectedVectors.add("su binary found")
    if (checkSuCommand()) detectedVectors.add("su command accessible")
    if (checkMagiskPaths()) detectedVectors.add("Magisk files detected")
    if (checkRootPackages()) detectedVectors.add("root management app installed")
    if (checkDangerousProps()) detectedVectors.add("dangerous system properties")
    if (checkWritableSystemPaths()) detectedVectors.add("system partition writable")

    val isRooted = detectedVectors.isNotEmpty()
    return mapOf(
      "type" to "rootedJailbroken",
      "isVulnerable" to isRooted,
      "message" to if (isRooted) "Device is rooted: ${detectedVectors.joinToString()}" else "Device is not rooted"
    )
  }

  private fun checkTestKeys(): Boolean {
    val buildTags = Build.TAGS
    return buildTags != null && buildTags.contains("test-keys")
  }

  private fun checkSuPaths(): Boolean {
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
      "/su/bin/su",
      "/system/xbin/mu"
    )
    return paths.any { File(it).exists() }
  }

  private fun checkSuCommand(): Boolean {
    var process: Process? = null
    return try {
      process = Runtime.getRuntime().exec(arrayOf("/system/xbin/which", "su"))
      val reader = java.io.BufferedReader(java.io.InputStreamReader(process.inputStream))
      reader.readLine() != null
    } catch (t: Throwable) {
      false
    } finally {
      process?.destroy()
    }
  }

  // Magisk-specific detection
  private fun checkMagiskPaths(): Boolean {
    val magiskPaths = arrayOf(
      "/sbin/.magisk",
      "/sbin/.core/mirror",
      "/sbin/.core/img",
      "/sbin/.core/db-0/magisk.db",
      "/data/adb/magisk",
      "/data/adb/magisk.db",
      "/data/adb/modules",
      "/cache/.disable_magisk",
      "/dev/magisk",
      "/system/xbin/ku.sud"
    )
    return magiskPaths.any { File(it).exists() }
  }

  // Check for root manager packages (Magisk Manager, SuperSU, KingRoot, etc.)
  private fun checkRootPackages(): Boolean {
    val rootPackages = listOf(
      "com.topjohnwu.magisk",          // Magisk Manager
      "io.github.huskydg.magisk",      // Magisk Delta
      "com.noshufou.android.su",       // SuperUser
      "com.noshufou.android.su.elite", // SuperUser Elite
      "eu.chainfire.supersu",          // SuperSU
      "com.koushikdutta.superuser",    // Superuser
      "com.thirdparty.superuser",
      "com.yellowes.su",
      "com.kingroot.kinguser",         // KingRoot
      "com.kingo.root",               // KingoRoot
      "com.smedialink.oneclickroot",
      "com.zhiqupk.root.global",
      "com.alephzain.framaroot",
      "com.zachspong.temprootremovejb",
      "com.ramdroid.appquarantine",
      "com.topjohnwu.magisk.stub"
    )
    val pm = context.packageManager
    return rootPackages.any { pkg ->
      try { pm.getPackageInfo(pkg, 0); true } catch (e: Exception) { false }
    }
  }

  // Check dangerous ro properties that indicate rooted/modified system
  private fun checkDangerousProps(): Boolean {
    val dangerousProps = mapOf(
      "ro.debuggable" to "1",
      "ro.secure" to "0",
      "ro.build.selinux" to "0"
    )
    return dangerousProps.any { (prop, dangerousValue) ->
      try {
        val process = Runtime.getRuntime().exec(arrayOf("getprop", prop))
        val reader = java.io.BufferedReader(java.io.InputStreamReader(process.inputStream))
        val value = reader.readLine()?.trim()
        process.destroy()
        value == dangerousValue
      } catch (e: Exception) {
        false
      }
    }
  }

  // Check if /system or /data is writable (indicates root)
  private fun checkWritableSystemPaths(): Boolean {
    val systemPaths = arrayOf("/system", "/system/bin", "/system/sbin", "/system/xbin", "/vendor/bin", "/sbin", "/etc")
    return systemPaths.any { path ->
      try {
        val file = File(path)
        file.exists() && file.canWrite()
      } catch (e: Exception) {
        false
      }
    }
  }

  fun checkDebuggable(): Map<String, Any> {
    val isDebuggable = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    val isDebugSigned = isSignedWithDebugKey()
    val isVulnerable = isDebuggable || isDebugSigned

    val message = when {
      isDebuggable && isDebugSigned -> "App is debuggable and signed with debug certificate (release APK not detected)"
      isDebuggable -> "App is debuggable"
      isDebugSigned -> "Release APK is signed with debug certificate — proper release signing required"
      else -> "App is not debuggable and is signed with a release certificate"
    }

    return mapOf(
      "type" to "debuggableApp",
      "isVulnerable" to isVulnerable,
      "message" to message
    )
  }

  private fun isSignedWithDebugKey(): Boolean {
    return try {
      val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        context.packageManager.getPackageInfo(
          context.packageName,
          PackageManager.GET_SIGNING_CERTIFICATES
        ).signingInfo?.apkContentsSigners
      } else {
        @Suppress("DEPRECATION")
        context.packageManager.getPackageInfo(
          context.packageName,
          PackageManager.GET_SIGNATURES
        ).signatures
      }
      signatures?.any { signature ->
        val cert = CertificateFactory.getInstance("X.509")
          .generateCertificate(ByteArrayInputStream(signature.toByteArray())) as X509Certificate
        val dn = cert.subjectX500Principal.name
        dn.contains("Android Debug", ignoreCase = true)
      } ?: false
    } catch (e: Exception) {
      false
    }
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
    // Only flag if there are non-framework prefs files — Flutter/system prefs are expected.
    // Known framework-created prefs that are not app-sensitive:
    val frameworkPrefsPrefixes = listOf(
      "FlutterSharedPreferences",
      "com.google.",
      "firebase.",
      "io.flutter.",
    )
    val files = sharedPrefsDir.listFiles() ?: emptyArray()
    val hasSensitivePrefs = files.any { file ->
      frameworkPrefsPrefixes.none { prefix -> file.name.startsWith(prefix) }
    }

    return mapOf(
      "type" to "insecureLocalStorage",
      "isVulnerable" to hasSensitivePrefs,
      "message" to if (hasSensitivePrefs)
        "App-specific unencrypted SharedPreferences found — consider using EncryptedSharedPreferences"
      else
        "No app-specific unencrypted SharedPreferences detected"
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
    // Only flag if sensitive file types exist — plain existence of the directory is not a risk.
    val sensitiveExtensions = setOf("db", "sqlite", "sqlite3", "key", "pem", "p12", "jks", "json", "xml", "txt")
    val hasSensitiveFiles = externalFilesDir?.walkTopDown()?.any { file ->
      file.isFile && file.extension.lowercase() in sensitiveExtensions
    } ?: false

    return mapOf(
      "type" to "externalStorageSensitiveData",
      "isVulnerable" to hasSensitiveFiles,
      "message" to if (hasSensitiveFiles)
        "Potentially sensitive files (db/key/config) found in external storage"
      else
        "No sensitive file types detected in external storage"
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

  suspend fun checkPlayIntegrity(): Map<String, Any> {
    return try {
      val nonce = Base64.encodeToString(
        UUID.randomUUID().toString().toByteArray(Charsets.UTF_8),
        Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING
      )
      val integrityManager = IntegrityManagerFactory.create(context)
      val tokenResponse = integrityManager
        .requestIntegrityToken(IntegrityTokenRequest.builder().setNonce(nonce).build())
        .await()

      mapOf(
        "type" to "playIntegrityFailed",
        "isVulnerable" to false,
        "message" to "Play Integrity token obtained. Send token to your server for full verdict verification.",
        "details" to mapOf(
          "token" to tokenResponse.token(),
          "nonce" to nonce
        )
      )
    } catch (e: Exception) {
      // Token request failed — treat as vulnerable since we cannot attest the device
      mapOf(
        "type" to "playIntegrityFailed",
        "isVulnerable" to true,
        "message" to "Play Integrity check failed: ${e.message}",
        "details" to mapOf("error" to (e.message ?: "Unknown error"))
      )
    }
  }
}