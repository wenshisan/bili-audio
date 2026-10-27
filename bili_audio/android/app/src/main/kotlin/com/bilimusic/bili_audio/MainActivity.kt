package com.bilimusic.bili_audio

import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.webkit.CookieManager
import androidx.core.content.FileProvider
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// audio_service 要求使用 AudioServiceActivity 以共享 FlutterEngine (M4.1)
class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "bili_audio/ui_mode")
            .setMethodCallHandler { call, result ->
                if (call.method == "isCar") {
                    val mode = resources.configuration.uiMode and Configuration.UI_MODE_TYPE_MASK
                    result.success(mode == Configuration.UI_MODE_TYPE_CAR)
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(messenger, "bili_audio/install")
            .setMethodCallHandler { call, result ->
                if (call.method != "installApk") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                if (path.isNullOrEmpty()) {
                    result.error("bad_args", "path required", null)
                    return@setMethodCallHandler
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                    !packageManager.canRequestPackageInstalls()
                ) {
                    startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                            Uri.parse("package:$packageName"),
                        ),
                    )
                    result.error("permission", "REQUEST_INSTALL_PACKAGES", null)
                    return@setMethodCallHandler
                }
                val uri = FileProvider.getUriForFile(
                    this,
                    "$packageName.fileprovider",
                    File(path),
                )
                startActivity(
                    Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "application/vnd.android.package-archive")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    },
                )
                result.success(null)
            }
        MethodChannel(messenger, "bili_audio/login_cookies")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "read" -> result.success(readLoginCookies())
                    "clear" -> CookieManager.getInstance().removeAllCookies {
                        runOnUiThread { result.success(null) }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// 返回 WebView 里哔哩哔哩的 Cookie 头。Dart 侧按第一个 `=` 拆开。
    private fun readLoginCookies(): String {
        val manager = CookieManager.getInstance()
        manager.setAcceptCookie(true)
        val urls = listOf(
            "https://www.bilibili.com",
            "https://passport.bilibili.com",
        )
        return urls.mapNotNull { manager.getCookie(it) }
            .filter { it.isNotEmpty() }
            .joinToString("; ")
    }
}
