package com.zeeje.word

import android.view.WindowManager
import android.os.Build
import android.content.Intent
import android.app.Activity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var documentResult: MethodChannel.Result? = null
    private var backupText: String? = null
    @Deprecated("Used for document picker compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 710 && requestCode != 711) return
        val reply = documentResult ?: return
        documentResult = null
        val text = backupText
        backupText = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) { reply.success(null); return }
        try {
            if (requestCode == 710) {
                contentResolver.openOutputStream(uri, "wt")!!.use { it.write(text!!.toByteArray(Charsets.UTF_8)) }
                reply.success(true)
            } else {
                val bytes = contentResolver.openInputStream(uri)!!.use { it.readBytesLimited() }
                reply.success(String(bytes, Charsets.UTF_8))
            }
        } catch (e: Exception) { reply.error("FILE", "Could not access the backup file.", null) }
    }
    private fun java.io.InputStream.readBytesLimited(): ByteArray {
        val output = java.io.ByteArrayOutputStream()
        val buffer = ByteArray(8192)
        while (true) {
            val n = read(buffer)
            if (n < 0) break
            if (output.size() + n > 8 * 1024 * 1024) throw IllegalArgumentException("Backup too large")
            output.write(buffer, 0, n)
        }
        return output.toByteArray()
    }

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
                    "exportBackup", "importBackup" -> {
                        if (documentResult != null) { result.error("BUSY", "A file picker is already open.", null) }
                        else {
                            val exporting = call.method == "exportBackup"
                            documentResult = result
                            backupText = call.arguments as? String
                            try {
                                val intent = Intent(if (exporting) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT)
                                intent.addCategory(Intent.CATEGORY_OPENABLE)
                                intent.type = if (exporting) "application/json" else "*/*"
                                if (exporting) intent.putExtra(Intent.EXTRA_TITLE, "Bible-backup.json")
                                startActivityForResult(intent, if (exporting) 710 else 711)
                            } catch (e: Exception) {
                                documentResult = null; backupText = null
                                result.error("FILE", "No document picker is available.", null)
                            }
                        }
                    }
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
