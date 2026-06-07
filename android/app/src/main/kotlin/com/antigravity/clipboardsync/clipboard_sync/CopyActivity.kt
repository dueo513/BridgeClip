package com.antigravity.clipboardsync.clipboard_sync

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.widget.Toast

class CopyActivity : Activity() {
    private var pendingText: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        try {
            val data: Uri? = intent.data
            if (data != null && data.scheme == "copysync" && data.host == "copy") {
                pendingText = data.getQueryParameter("text")
            } else {
                finish()
            }
        } catch (e: Exception) {
            Log.e("CopyActivity", "Failed to parse copy intent.", e)
            finish()
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus) return

        val text = pendingText
        if (text != null) {
            try {
                val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                val clip = ClipData.newPlainText("BridgeClip text", text)
                clipboard.setPrimaryClip(clip)
                Toast.makeText(this, "Copied to clipboard.", Toast.LENGTH_SHORT).show()
            } catch (e: Exception) {
                Log.e("CopyActivity", "Clipboard write failed.", e)
            }
        }
        finish()
    }
}
