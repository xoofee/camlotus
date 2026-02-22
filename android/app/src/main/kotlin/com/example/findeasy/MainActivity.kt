package com.example.camlotus

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.camlotus/install_source"
    private val INSTALL_CHANNEL = "com.example.camlotus/install_apk"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Install source channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstallerPackageName" -> {
                    try {
                        val installerPackageName = packageManager.getInstallerPackageName(packageName)
                        result.success(installerPackageName)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get installer package name", e.message)
                    }
                }
                "openInstallPermissionSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            // Android 8.0+ - Open "Install unknown apps" settings
                            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            // Android < 8.0 - Open general security settings
                            val intent = Intent(Settings.ACTION_SECURITY_SETTINGS)
                            startActivity(intent)
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open install permission settings", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // APK installation channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    try {
                        val filePath = call.argument<String>("filePath")
                        val authority = call.argument<String>("authority")
                        if (filePath != null && authority != null) {
                            val file = File(filePath)
                            if (!file.exists()) {
                                result.error("ERROR", "APK file does not exist: $filePath", null)
                                return@setMethodCallHandler
                            }
                            
                            // Use FileProvider to create content URI
                            val uri = FileProvider.getUriForFile(this, authority, file)
                            
                            // Create intent to install APK
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/vnd.android.package-archive")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            
                            // Verify that the intent can be resolved
                            if (intent.resolveActivity(packageManager) != null) {
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.error("ERROR", "No app can handle APK installation", null)
                            }
                        } else {
                            result.error("ERROR", "Missing filePath or authority", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to install APK: ${e.message}", e.stackTrace.toString())
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
