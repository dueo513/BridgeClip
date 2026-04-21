package com.antigravity.clipboardsync.clipboard_sync

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.antigravity/quick_sync"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "checkQuickSync") {
                val isQuickSync = intent?.getBooleanExtra("quick_sync", false) ?: false
                if (isQuickSync) {
                    intent?.removeExtra("quick_sync")
                }
                result.success(isQuickSync)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        this.intent = intent // Update the intent so it can be picked up
    }
}
