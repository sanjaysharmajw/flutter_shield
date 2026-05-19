package com.example.flutter_shield

import android.app.Activity
import android.content.ClipboardManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayInputStream
import java.io.File
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate

class FlutterShieldPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private lateinit var securityChecker: SecurityChecker

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_shield")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
    securityChecker = SecurityChecker(context)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    securityChecker.activity = binding.activity
  }
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    securityChecker.activity = binding.activity
  }
  override fun onDetachedFromActivityForConfigChanges() {
    securityChecker.activity = null
  }
  override fun onDetachedFromActivity() {
    securityChecker.activity = null
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
  var activity: Activity? = null

  fun checkRoot(): Map<String, Any> {
    val detectedVectors = mutableListOf<String>()

    if (checkTestKeys()) detectedVectors.add("test-keys build")
    if (checkSuPaths()) detectedVectors.add("su binary found")
    if (checkSuCommand()) detectedVectors.add("su command accessible")
    if (checkMagiskPaths()) detectedVectors.add("Magisk/KSU/APatch files detected")
    if (checkRootPackages()) detectedVectors.add("root management app installed")
    if (checkDangerousProps()) detectedVectors.add("dangerous system properties")
    if (checkWritableSystemPaths()) detectedVectors.add("system partition writable")
    if (checkSeLinuxPermissive()) detectedVectors.add("SELinux permissive mode")
    if (checkMagiskSocket()) detectedVectors.add("Magisk daemon socket found")
    if (checkZygiskMaps()) detectedVectors.add("Zygisk injected in process maps")

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

  // Bug fix: hardcoded /system/xbin/which misses most devices; try both locations.
  // Bug fix: stderr must be consumed — unconsumed streams deadlock on some devices.
  // Bug fix: waitFor() before destroy() to avoid zombie processes.
  // Bug fix: waitFor without timeout blocks indefinitely if process hangs — use 3 s limit.
  private fun checkSuCommand(): Boolean {
    val whichPaths = arrayOf("/system/bin/which", "/system/xbin/which", "which")
    for (whichBin in whichPaths) {
      var process: Process? = null
      try {
        process = Runtime.getRuntime().exec(arrayOf(whichBin, "su"))
        process.errorStream.close() // consume stderr to prevent deadlock
        val reader = java.io.BufferedReader(java.io.InputStreamReader(process.inputStream))
        val found = reader.readLine() != null
        reader.close()
        process.waitFor(3, java.util.concurrent.TimeUnit.SECONDS)
        if (found) return true
      } catch (_: Throwable) {
        // path not found — try next
      } finally {
        process?.destroy()
      }
    }
    return false
  }

  // Magisk / KernelSU / APatch path detection
  private fun checkMagiskPaths(): Boolean {
    val paths = arrayOf(
      // Magisk
      "/sbin/.magisk",
      "/sbin/.core/mirror",
      "/sbin/.core/img",
      "/sbin/.core/db-0/magisk.db",
      "/data/adb/magisk",
      "/data/adb/magisk.db",
      "/data/adb/modules",
      "/cache/.disable_magisk",
      "/dev/magisk",
      "/system/xbin/ku.sud",
      // KernelSU
      "/data/adb/ksu",
      "/data/adb/ksud",
      "/data/adb/ksu/bin/ksud",
      // APatch
      "/data/adb/ap",
      "/data/adb/apatch",
    )
    if (paths.any { File(it).exists() }) return true
    return checkMagiskMounts()
  }

  // /proc/mounts check — survives Magisk Hide / Zygisk path hiding
  private fun checkMagiskMounts(): Boolean {
    return try {
      File("/proc/mounts").bufferedReader().useLines { lines ->
        lines.any { line ->
          line.contains("magisk", ignoreCase = true) ||
          line.contains("KSU", ignoreCase = true) ||
          line.contains("kernelsu", ignoreCase = true) ||
          line.contains("apatch", ignoreCase = true)
        }
      }
    } catch (_: Exception) {
      false
    }
  }

  // Check for root manager packages (Magisk, KernelSU, APatch, SuperSU, KingRoot, etc.)
  private fun checkRootPackages(): Boolean {
    val rootPackages = listOf(
      "com.topjohnwu.magisk",          // Magisk Manager
      "io.github.huskydg.magisk",      // Magisk Delta
      "com.topjohnwu.magisk.stub",     // Magisk stub
      "me.weishu.kernelsu",            // KernelSU Manager
      "me.bmax.apatch",                // APatch Manager
      "com.noshufou.android.su",       // SuperUser
      "com.noshufou.android.su.elite", // SuperUser Elite
      "eu.chainfire.supersu",          // SuperSU
      "com.koushikdutta.superuser",    // Superuser
      "com.thirdparty.superuser",
      "com.yellowes.su",
      "com.kingroot.kinguser",         // KingRoot
      "com.kingo.root",                // KingoRoot
      "com.smedialink.oneclickroot",
      "com.zhiqupk.root.global",
      "com.alephzain.framaroot",
      "com.zachspong.temprootremovejb",
      "com.ramdroid.appquarantine",
    )
    val pm = context.packageManager
    return rootPackages.any { pkg ->
      try { pm.getPackageInfo(pkg, 0); true } catch (e: Exception) { false }
    }
  }

  // Check dangerous ro properties that indicate rooted/modified system
  // Bug fix: stderr consumed + waitFor(timeout) + destroy() to prevent zombie processes and hangs.
  // Bug fix: ro.build.type must also check "eng" — engineering builds are equally dangerous.
  private fun checkDangerousProps(): Boolean {
    val dangerousProps = listOf(
      "ro.debuggable" to setOf("1"),
      "ro.secure" to setOf("0"),
      "ro.build.selinux" to setOf("0"),
      "ro.build.type" to setOf("userdebug", "eng"),  // both indicate unlocked/debug build
    )
    return dangerousProps.any { (prop, dangerousValues) ->
      try {
        val process = Runtime.getRuntime().exec(arrayOf("getprop", prop))
        process.errorStream.close()
        val reader = java.io.BufferedReader(java.io.InputStreamReader(process.inputStream))
        val value = reader.readLine()?.trim()
        reader.close()
        process.waitFor(3, java.util.concurrent.TimeUnit.SECONDS)
        process.destroy()
        value != null && value in dangerousValues
      } catch (_: Exception) {
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

  // SELinux permissive = root almost certain (Magisk can set it permissive on older kernels)
  private fun checkSeLinuxPermissive(): Boolean {
    return try {
      val process = Runtime.getRuntime().exec("getenforce")
      process.errorStream.close()
      val reader = java.io.BufferedReader(java.io.InputStreamReader(process.inputStream))
      val value = reader.readLine()?.trim()
      reader.close()
      process.waitFor(3, java.util.concurrent.TimeUnit.SECONDS)
      process.destroy()
      value?.equals("Permissive", ignoreCase = true) == true
    } catch (_: Exception) {
      false
    }
  }

  // Magisk daemon communicates via abstract Unix socket @magisk_service — survives path hiding
  private fun checkMagiskSocket(): Boolean {
    return try {
      File("/proc/net/unix").bufferedReader().useLines { lines ->
        lines.any { line ->
          line.contains("@magisk", ignoreCase = true) ||
          line.contains("@ksu_", ignoreCase = true)
        }
      }
    } catch (_: Exception) {
      false
    }
  }

  // Zygisk injects into every process — its native lib appears in /proc/self/maps
  private fun checkZygiskMaps(): Boolean {
    return try {
      File("/proc/self/maps").bufferedReader().useLines { lines ->
        lines.any { line ->
          line.contains("zygisk", ignoreCase = true) ||
          line.contains("magisk", ignoreCase = true) ||
          line.contains("/data/adb/modules", ignoreCase = true)
        }
      }
    } catch (_: Exception) {
      false
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
    val knownMalicious = listOf(
      // Stalkerware / commercial spyware
      "com.mspy.android", "com.mspy.android.sn", "org.mspy",
      "com.flexispy.android", "com.highster.mobile",
      "com.ikeymonitor", "com.ispyoo.android",
      "com.clevguard.android", "net.clevguard",
      "com.hoverwatch", "com.spyzie.android",
      "com.cocospy.android", "com.umobix.android",
      "com.mobilespy.android", "com.trackview",
      "com.spymaster.android", "com.reptilicus.android",
      "com.copy9.android", "com.phonebeagle",
      "com.mobistealth.android", "com.iamspy",
      // Remote-access trojans
      "com.metasploit.stage", "com.androrat.android",
      "com.omerta.rat", "com.dendroid.rat",
      // Banking trojans / common malware families
      "com.bankbot.android", "com.cerberus.android",
      "com.anubis.android", "com.hydra.android",
      "com.alien.android", "com.gustuff.android",
      // Fake security / scareware
      "com.virus.cleaner.fake", "com.fake.antivirus",
      "com.android.system.update.fake",
    )
    val pm = context.packageManager
    val found = knownMalicious.filter { pkg ->
      try { pm.getPackageInfo(pkg, 0); true } catch (_: Exception) { false }
    }
    return mapOf(
      "type" to "malwareExposure",
      "isVulnerable" to found.isNotEmpty(),
      "message" to if (found.isNotEmpty())
        "Known malicious/stalkerware apps detected: ${found.joinToString()}"
      else
        "No known malicious apps detected"
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
    return try {
      val ks = java.security.KeyStore.getInstance("AndroidKeyStore")
      ks.load(null)
      val aliases = ks.aliases().toList()
      mapOf(
        "type" to "improperKeychainKeystore",
        "isVulnerable" to aliases.isEmpty(),
        "message" to if (aliases.isEmpty())
          "Android Keystore is empty — sensitive keys should be stored in the Keystore, not in SharedPreferences or files"
        else
          "Android Keystore in use (${aliases.size} key entry(s) found)"
      )
    } catch (e: Exception) {
      mapOf(
        "type" to "improperKeychainKeystore",
        "isVulnerable" to true,
        "message" to "Failed to access Android Keystore: ${e.message}"
      )
    }
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
    // walkTopDown on external storage can throw SecurityException or IOException on permission errors
    val hasSensitiveFiles = try {
      externalFilesDir?.walkTopDown()?.any { file ->
        file.isFile && file.extension.lowercase() in sensitiveExtensions
      } ?: false
    } catch (_: Exception) { false }

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
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
      return mapOf(
        "type" to "weakBiometricHandling",
        "isVulnerable" to false,
        "message" to "BiometricManager requires Android 10+ — verify biometric handling manually on this device"
      )
    }
    val bm = context.getSystemService(android.hardware.biometrics.BiometricManager::class.java)
    return when (bm?.canAuthenticate(android.hardware.biometrics.BiometricManager.Authenticators.BIOMETRIC_STRONG)) {
      android.hardware.biometrics.BiometricManager.BIOMETRIC_SUCCESS ->
        mapOf("type" to "weakBiometricHandling", "isVulnerable" to false,
          "message" to "Strong biometric authentication is available and configured")
      android.hardware.biometrics.BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE ->
        mapOf("type" to "weakBiometricHandling", "isVulnerable" to true,
          "message" to "No biometric hardware detected on this device")
      android.hardware.biometrics.BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED ->
        mapOf("type" to "weakBiometricHandling", "isVulnerable" to true,
          "message" to "No biometrics enrolled — users cannot authenticate with biometrics")
      android.hardware.biometrics.BiometricManager.BIOMETRIC_ERROR_SECURITY_UPDATE_REQUIRED ->
        mapOf("type" to "weakBiometricHandling", "isVulnerable" to true,
          "message" to "Biometric security update required to meet strong authentication standards")
      else ->
        mapOf("type" to "weakBiometricHandling", "isVulnerable" to false,
          "message" to "Biometric status could not be determined")
    }
  }

  fun checkBiometricBypass(): Map<String, Any> {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
      return mapOf("type" to "biometricBypass", "isVulnerable" to false,
        "message" to "Biometric bypass check requires Android 10+")
    }
    val bm = context.getSystemService(android.hardware.biometrics.BiometricManager::class.java)
    val strongOk = bm?.canAuthenticate(android.hardware.biometrics.BiometricManager.Authenticators.BIOMETRIC_STRONG) ==
      android.hardware.biometrics.BiometricManager.BIOMETRIC_SUCCESS
    val weakOk = bm?.canAuthenticate(android.hardware.biometrics.BiometricManager.Authenticators.BIOMETRIC_WEAK) ==
      android.hardware.biometrics.BiometricManager.BIOMETRIC_SUCCESS
    // Vulnerable if only weak biometric (face/iris) is available — susceptible to photo/mask bypass
    val vulnerable = !strongOk && weakOk
    return mapOf(
      "type" to "biometricBypass",
      "isVulnerable" to vulnerable,
      "message" to if (vulnerable)
        "Only weak biometric (face/iris) available — susceptible to bypass via photo or mask. Use BIOMETRIC_STRONG."
      else if (strongOk)
        "Strong biometric (fingerprint) enforced — bypass resistance is adequate"
      else
        "No biometric enrolled — bypass check not applicable"
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
    val act = activity ?: return mapOf("type" to "screenshotNotRestricted",
      "isVulnerable" to true,
      "message" to "Screenshot check unavailable — activity not attached; assume vulnerable")
    val flagSecure = (act.window.attributes.flags and WindowManager.LayoutParams.FLAG_SECURE) != 0
    return mapOf(
      "type" to "screenshotNotRestricted",
      "isVulnerable" to !flagSecure,
      "message" to if (flagSecure)
        "Screenshots are restricted via FLAG_SECURE"
      else
        "Screenshots are not restricted — add FLAG_SECURE to your Activity window to prevent screen capture"
    )
  }

  fun checkScreenRecording(): Map<String, Any> {
    val act = activity ?: return mapOf("type" to "screenRecordingNotRestricted",
      "isVulnerable" to true,
      "message" to "Screen recording check unavailable — activity not attached; assume vulnerable")
    // FLAG_SECURE blocks both screenshots and screen recording on Android
    val flagSecure = (act.window.attributes.flags and WindowManager.LayoutParams.FLAG_SECURE) != 0
    return mapOf(
      "type" to "screenRecordingNotRestricted",
      "isVulnerable" to !flagSecure,
      "message" to if (flagSecure)
        "Screen recording is blocked via FLAG_SECURE"
      else
        "Screen recording is not restricted — FLAG_SECURE prevents both screenshots and screen recording"
    )
  }

  fun checkClipboard(): Map<String, Any> {
    return try {
      val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
      if (!cm.hasPrimaryClip()) {
        return mapOf("type" to "clipboardLeakage", "isVulnerable" to false,
          "message" to "Clipboard is empty")
      }
      val text = cm.primaryClip?.getItemAt(0)?.text?.toString()
        ?: return mapOf("type" to "clipboardLeakage", "isVulnerable" to false,
          "message" to "Clipboard contains non-text data")

      val sensitivePatterns = listOf(
        Regex("""\b\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{4}\b"""),                // credit card
        Regex("""\b\d{3}-\d{2}-\d{4}\b"""),                                          // SSN
        Regex("""(?i)password[\s:=]+\S+"""),                                          // password field
        Regex("""(?i)(api[_\-]?key|secret[_\-]?key|access[_\-]?token)[\s:=]+\S+"""),// API key/token
        Regex("""(?i)Bearer\s+[A-Za-z0-9\-._~+/]+=*"""),                            // Bearer token
        // Private key header — highly specific, no false positives
        Regex("""-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----"""),
      )
      val hasSensitive = sensitivePatterns.any { it.containsMatchIn(text) }
      mapOf(
        "type" to "clipboardLeakage",
        "isVulnerable" to hasSensitive,
        "message" to if (hasSensitive)
          "Clipboard appears to contain sensitive data (credit card, token, password, or key pattern detected)"
        else
          "Clipboard content does not match known sensitive patterns"
      )
    } catch (e: Exception) {
      mapOf("type" to "clipboardLeakage", "isVulnerable" to false,
        "message" to "Clipboard check unavailable: ${e.message}")
    }
  }

  fun checkOverlay(): Map<String, Any> {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
      return mapOf("type" to "overlayAttack", "isVulnerable" to false,
        "message" to "Overlay permission management not available below Android 6.0")
    }
    return try {
      val pm = context.packageManager
      @Suppress("DEPRECATION")
      val overlayApps = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
        .filter { pkg ->
          pkg.packageName != context.packageName &&
          (pkg.applicationInfo?.flags?.and(ApplicationInfo.FLAG_SYSTEM) ?: 0) == 0 &&
          pkg.requestedPermissions?.contains(android.Manifest.permission.SYSTEM_ALERT_WINDOW) == true
        }
        .map { it.packageName }
      mapOf(
        "type" to "overlayAttack",
        "isVulnerable" to overlayApps.isNotEmpty(),
        "message" to if (overlayApps.isNotEmpty())
          "${overlayApps.size} third-party app(s) declare overlay (SYSTEM_ALERT_WINDOW) permission: ${overlayApps.take(3).joinToString()}"
        else
          "No third-party apps with overlay permission found"
      )
    } catch (e: Exception) {
      mapOf("type" to "overlayAttack", "isVulnerable" to false,
        "message" to "Overlay check failed: ${e.message}")
    }
  }

  fun checkBackgroundData(): Map<String, Any> {
    val act = activity ?: return mapOf("type" to "backgroundDataExposure",
      "isVulnerable" to true,
      "message" to "Background data check unavailable — activity not attached; assume vulnerable")
    val flagSecure = (act.window.attributes.flags and WindowManager.LayoutParams.FLAG_SECURE) != 0
    return mapOf(
      "type" to "backgroundDataExposure",
      "isVulnerable" to !flagSecure,
      "message" to if (flagSecure)
        "Background data exposure mitigated via FLAG_SECURE"
      else
        "Sensitive UI content may be visible in app switcher — use FLAG_SECURE or clear sensitive views in onPause()"
    )
  }

  fun checkRecentApps(): Map<String, Any> {
    val act = activity ?: return mapOf("type" to "recentAppsExposure",
      "isVulnerable" to true,
      "message" to "Recent apps check unavailable — activity not attached; assume vulnerable")
    val flagSecure = (act.window.attributes.flags and WindowManager.LayoutParams.FLAG_SECURE) != 0
    return mapOf(
      "type" to "recentAppsExposure",
      "isVulnerable" to !flagSecure,
      "message" to if (flagSecure)
        "Recent apps thumbnail is protected via FLAG_SECURE"
      else
        "App content visible in recent apps — add FLAG_SECURE to prevent content leakage in task switcher"
    )
  }

  fun checkIPC(): Map<String, Any> {
    return try {
      val pm = context.packageManager
      @Suppress("DEPRECATION")
      val info = pm.getPackageInfo(context.packageName, PackageManager.GET_PROVIDERS)
      val exposed = info.providers?.filter { p ->
        p.exported && p.readPermission == null && p.writePermission == null
      }?.map { it.name.substringAfterLast('.') } ?: emptyList()
      mapOf(
        "type" to "insecureIPC",
        "isVulnerable" to exposed.isNotEmpty(),
        "message" to if (exposed.isNotEmpty())
          "${exposed.size} ContentProvider(s) exported without read/write permission: ${exposed.joinToString()}"
        else
          "No unprotected exported ContentProviders found"
      )
    } catch (e: Exception) {
      mapOf("type" to "insecureIPC", "isVulnerable" to false,
        "message" to "IPC check failed: ${e.message}")
    }
  }

  fun checkIntentHijacking(): Map<String, Any> {
    return try {
      val pm = context.packageManager
      @Suppress("DEPRECATION")
      val info = pm.getPackageInfo(context.packageName, PackageManager.GET_ACTIVITIES)
      val exposed = info.activities?.filter { a ->
        a.exported && a.permission == null &&
        // Exclude the main launcher activity — intentionally exported
        !a.name.endsWith("MainActivity") && !a.name.endsWith("LaunchActivity")
      }?.map { it.name.substringAfterLast('.') } ?: emptyList()
      mapOf(
        "type" to "intentHijacking",
        "isVulnerable" to exposed.isNotEmpty(),
        "message" to if (exposed.isNotEmpty())
          "${exposed.size} Activity(ies) exported without permission protection: ${exposed.joinToString()}"
        else
          "No unprotected exported Activities found"
      )
    } catch (e: Exception) {
      mapOf("type" to "intentHijacking", "isVulnerable" to false,
        "message" to "Intent hijacking check failed: ${e.message}")
    }
  }

  fun checkBroadcastReceiver(): Map<String, Any> {
    return try {
      val pm = context.packageManager
      @Suppress("DEPRECATION")
      val info = pm.getPackageInfo(context.packageName, PackageManager.GET_RECEIVERS)
      val exposed = info.receivers?.filter { r ->
        r.exported && r.permission == null
      }?.map { it.name.substringAfterLast('.') } ?: emptyList()
      mapOf(
        "type" to "broadcastReceiverExposure",
        "isVulnerable" to exposed.isNotEmpty(),
        "message" to if (exposed.isNotEmpty())
          "${exposed.size} BroadcastReceiver(s) exported without permission: ${exposed.joinToString()}"
        else
          "No unprotected exported BroadcastReceivers found"
      )
    } catch (e: Exception) {
      mapOf("type" to "broadcastReceiverExposure", "isVulnerable" to false,
        "message" to "Broadcast receiver check failed: ${e.message}")
    }
  }

  fun checkDeepLink(): Map<String, Any> {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      return try {
        val dvm = context.getSystemService(
          android.content.pm.verify.domain.DomainVerificationManager::class.java
        )
        val userState = dvm?.getDomainVerificationUserState(context.packageName)
        val hostMap = userState?.hostToStateMap ?: emptyMap()
        val unverified = hostMap.filter { (_, state) ->
          state == android.content.pm.verify.domain.DomainVerificationUserState.DOMAIN_STATE_NONE
        }.keys.toList()
        when {
          hostMap.isEmpty() -> mapOf(
            "type" to "deepLinkHijacking", "isVulnerable" to false,
            "message" to "No App Links configured — if using deep links, add android:autoVerify=\"true\""
          )
          unverified.isNotEmpty() -> mapOf(
            "type" to "deepLinkHijacking", "isVulnerable" to true,
            "message" to "${unverified.size} domain(s) not verified via App Links: ${unverified.take(3).joinToString()}"
          )
          else -> mapOf(
            "type" to "deepLinkHijacking", "isVulnerable" to false,
            "message" to "All ${hostMap.size} App Links domain(s) are verified"
          )
        }
      } catch (e: Exception) {
        mapOf("type" to "deepLinkHijacking", "isVulnerable" to false,
          "message" to "Deep link check failed: ${e.message}")
      }
    }
    // Below Android 12: check for exported activities other than the known launcher entry points
    return try {
      val pm = context.packageManager
      @Suppress("DEPRECATION")
      val info = pm.getPackageInfo(context.packageName, PackageManager.GET_ACTIVITIES)
      val exposed = info.activities?.filter { a ->
        a.exported &&
        !a.name.endsWith("MainActivity") &&
        !a.name.endsWith("LaunchActivity") &&
        !a.name.endsWith("FlutterActivity")
      }?.map { it.name.substringAfterLast('.') } ?: emptyList()
      mapOf(
        "type" to "deepLinkHijacking",
        "isVulnerable" to exposed.isNotEmpty(),
        "message" to if (exposed.isNotEmpty())
          "${exposed.size} exported Activity(ies) may handle deep links without verification: ${exposed.joinToString()} — use android:autoVerify=\"true\" (Android 12+ required for full check)"
        else
          "No unprotected deep-link Activities detected (Android 12+ required for full App Links verification)"
      )
    } catch (e: Exception) {
      mapOf("type" to "deepLinkHijacking", "isVulnerable" to false,
        "message" to "Deep link check failed: ${e.message}")
    }
  }

  fun checkWebViewDebugging(): Map<String, Any> {
    // WebView.setWebContentsDebuggingEnabled() is typically called only in debug builds.
    // Use FLAG_DEBUGGABLE as a reliable proxy — production apps must not have this flag.
    val isDebuggable = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    return mapOf(
      "type" to "webViewDebugging",
      "isVulnerable" to isDebuggable,
      "message" to if (isDebuggable)
        "App is debuggable — WebView.setWebContentsDebuggingEnabled(true) likely active; attackers can inspect WebView via Chrome DevTools"
      else
        "App is not debuggable — WebView remote debugging should be disabled in this build"
    )
  }

  fun checkWebViewJavaScript(): Map<String, Any> {
    // getCurrentWebViewPackage() requires API 26 — use FLAG_DEBUGGABLE as proxy on older devices
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
      val debuggable = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
      return mapOf(
        "type" to "webViewJavaScriptAbuse",
        "isVulnerable" to debuggable,
        "message" to if (debuggable)
          "App is debuggable on Android < 8.0 — WebView JS abuse risk elevated"
        else
          "WebView version check requires Android 8.0+ — app appears non-debuggable"
      )
    }
    return try {
      val pkg = android.webkit.WebView.getCurrentWebViewPackage()
        ?: return mapOf("type" to "webViewJavaScriptAbuse", "isVulnerable" to false,
          "message" to "WebView not available on this device")
      val major = pkg.versionName?.substringBefore('.')?.toIntOrNull() ?: 0
      val outdated = major in 1..99
      mapOf(
        "type" to "webViewJavaScriptAbuse",
        "isVulnerable" to outdated,
        "message" to if (outdated)
          "WebView (${pkg.packageName} v${pkg.versionName}) is outdated — update to fix known JS/CVE vulnerabilities"
        else
          "WebView (${pkg.packageName} v${pkg.versionName}) is up to date"
      )
    } catch (e: Exception) {
      mapOf("type" to "webViewJavaScriptAbuse", "isVulnerable" to false,
        "message" to "WebView version check failed: ${e.message}")
    }
  }

  fun checkPermissions(): Map<String, Any> {
    // High-risk permissions — their presence in the manifest warrants review
    val highRisk = mapOf(
      android.Manifest.permission.READ_SMS to "READ_SMS",
      android.Manifest.permission.RECEIVE_SMS to "RECEIVE_SMS",
      android.Manifest.permission.SEND_SMS to "SEND_SMS",
      android.Manifest.permission.READ_CALL_LOG to "READ_CALL_LOG",
      android.Manifest.permission.WRITE_CALL_LOG to "WRITE_CALL_LOG",
      "android.permission.PROCESS_OUTGOING_CALLS" to "PROCESS_OUTGOING_CALLS",
      "android.permission.MANAGE_EXTERNAL_STORAGE" to "MANAGE_EXTERNAL_STORAGE",
      "android.permission.REQUEST_INSTALL_PACKAGES" to "REQUEST_INSTALL_PACKAGES",
      "android.permission.BIND_ACCESSIBILITY_SERVICE" to "BIND_ACCESSIBILITY_SERVICE",
      "android.permission.BIND_DEVICE_ADMIN" to "BIND_DEVICE_ADMIN",
    )
    return try {
      val pm = context.packageManager
      @Suppress("DEPRECATION")
      val declared = pm.getPackageInfo(context.packageName, PackageManager.GET_PERMISSIONS)
        .requestedPermissions ?: emptyArray()
      val found = highRisk.filter { (perm, _) -> declared.contains(perm) }.values.toList()
      mapOf(
        "type" to "runtimePermissionMissing",
        "isVulnerable" to found.isNotEmpty(),
        "message" to if (found.isNotEmpty())
          "High-risk permissions declared in manifest: ${found.joinToString()} — verify each is necessary"
        else
          "No high-risk permissions declared in manifest"
      )
    } catch (e: Exception) {
      mapOf("type" to "runtimePermissionMissing", "isVulnerable" to false,
        "message" to "Permission check failed: ${e.message}")
    }
  }

  fun checkAutofill(): Map<String, Any> {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
      return mapOf("type" to "insecureAutofill", "isVulnerable" to false,
        "message" to "Autofill framework not available below Android 8.0")
    }
    return try {
      val am = context.getSystemService(android.view.autofill.AutofillManager::class.java)
      val enabled = am?.isEnabled == true
      mapOf(
        "type" to "insecureAutofill",
        "isVulnerable" to enabled,
        "message" to if (enabled)
          "System autofill is active — ensure sensitive fields set android:importantForAutofill=\"no\" to prevent credential leakage"
        else
          "Autofill is not active on this device"
      )
    } catch (e: Exception) {
      mapOf("type" to "insecureAutofill", "isVulnerable" to false,
        "message" to "Autofill check failed: ${e.message}")
    }
  }

  fun checkSensors(): Map<String, Any> {
    // checkSelfPermission() requires API 23 — on API 21/22 all install-time permissions are granted
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
      return mapOf("type" to "sensorAbuse", "isVulnerable" to false,
        "message" to "Sensor permission check requires Android 6.0+ — permissions were granted at install time on this device")
    }
    val sensorPerms = mapOf(
      android.Manifest.permission.CAMERA to "Camera",
      android.Manifest.permission.RECORD_AUDIO to "Microphone",
      android.Manifest.permission.ACCESS_FINE_LOCATION to "GPS/Fine Location",
      android.Manifest.permission.BODY_SENSORS to "Body Sensors",
    )
    val granted = sensorPerms
      .filter { (perm, _) -> context.checkSelfPermission(perm) == PackageManager.PERMISSION_GRANTED }
      .values.toList()
    return mapOf(
      "type" to "sensorAbuse",
      "isVulnerable" to granted.isNotEmpty(),
      "message" to if (granted.isNotEmpty())
        "Sensitive sensor permissions currently granted: ${granted.joinToString()} — verify background access is restricted"
      else
        "No sensitive sensor permissions currently granted"
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
    val issues = mutableListOf<String>()
    val logExts = setOf("log", "trace", "dump")
    // Log files in app storage can leak sensitive data via adb or direct file access
    try {
      if (context.filesDir.walkTopDown().any { it.isFile && it.extension.lowercase() in logExts })
        issues.add("log/trace files in internal storage")
    } catch (_: Exception) {}
    try {
      if (context.cacheDir.listFiles()?.any { it.extension.lowercase() in logExts } == true)
        issues.add("debug artifacts in cache directory")
    } catch (_: Exception) {}
    // Debuggable flag exposes all Log.d/v output to any app via logcat
    if ((context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0)
      issues.add("debuggable flag enables full logcat side-channel")
    return mapOf(
      "type" to "sideChannelAttacks",
      "isVulnerable" to issues.isNotEmpty(),
      "message" to if (issues.isNotEmpty())
        "Side-channel risk detected: ${issues.joinToString()}"
      else
        "No obvious side-channel vulnerabilities detected"
    )
  }

}