package com.bilimusic.bili_audio

import android.content.res.Configuration
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// audio_service 要求使用 AudioServiceActivity 以共享 FlutterEngine (M4.1)
class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bili_audio/ui_mode")
            .setMethodCallHandler { call, result ->
                if (call.method == "isCar") {
                    val mode = resources.configuration.uiMode and Configuration.UI_MODE_TYPE_MASK
                    result.success(mode == Configuration.UI_MODE_TYPE_CAR)
                } else {
                    result.notImplemented()
                }
            }
    }
}
