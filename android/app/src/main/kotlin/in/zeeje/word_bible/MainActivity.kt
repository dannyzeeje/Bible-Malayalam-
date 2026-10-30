package com.zeeje.word

import android.view.WindowManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onResume() {
        super.onResume()
        requestHighestRefreshRate()
    }
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) requestHighestRefreshRate()
    }
    @Suppress("DEPRECATION")
    private fun requestHighestRefreshRate() {
        val screen = if (Build.VERSION.SDK_INT >= 30) display else windowManager.defaultDisplay
        if (screen == null) return
        val current = screen.mode
        val fastest = screen.supportedModes
            .filter { it.physicalWidth == current.physicalWidth && it.physicalHeight == current.physicalHeight }
            .maxByOrNull { it.refreshRate } ?: return
        val params = window.attributes
        if (params.preferredDisplayModeId == fastest.modeId && params.preferredRefreshRate == fastest.refreshRate) return
        params.preferredDisplayModeId = fastest.modeId
        params.preferredRefreshRate = fastest.refreshRate
        window.attributes = params
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val prefs = getSharedPreferences("word_state", MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "word.bible/storage")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "awake" -> {
                        if (call.arguments == true) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        result.success(null)
                    }
                    "read" -> result.success(prefs.getString("state", "{}"))
                    "write" -> {
                        val data = call.arguments as? String
                        if (data == null) result.error("INVALID", "Missing state", null)
                        else {
                            prefs.edit().putString("state", data).apply()
                            result.success(true)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
