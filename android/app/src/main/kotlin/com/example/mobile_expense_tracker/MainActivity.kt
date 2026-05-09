package com.example.mobile_expense_tracker

import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.mobile_expense_tracker/update"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "installApk") {
                val path = call.argument<String>("path") ?: run {
                    result.error("INVALID_PATH", "APK path is null", null)
                    return@setMethodCallHandler
                }
                installApk(path, result)
            } else if (call.method == "restartApp") {
                restartApp()
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun restartApp() {
        val intent = packageManager.getLaunchIntentForPackage(packageName)!!
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        startActivity(intent)
        Runtime.getRuntime().exit(0)
    }

    private fun installApk(path: String, result: MethodChannel.Result) {
        try {
            val file = File(path)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "APK file not found at $path", null)
                return
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !packageManager.canRequestPackageInstalls()) {
                val uri = Uri.parse("package:${packageName}")
                val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, uri)
                startActivity(intent)
                result.success("redirected_to_settings")
                return
            }

            val uri = FileProvider.getUriForFile(this, "${applicationContext.packageName}.fileprovider", file)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            startActivity(intent)
            result.success("installing")
        } catch (e: Exception) {
            result.error("INSTALL_ERROR", e.message, null)
        }
    }
}
