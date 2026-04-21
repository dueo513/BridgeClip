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
            val pIntent = intent
            val data: Uri? = pIntent.data

            if (data != null && data.scheme == "copysync" && data.host == "copy") {
                pendingText = data.getQueryParameter("text")
            } else {
                finish()
            }
        } catch (e: Exception) {
            Log.e("CopyActivity", "인텐트 파싱 실패", e)
            finish()
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            if (pendingText != null) {
                try {
                    val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    val clip = ClipData.newPlainText("Copied Text", pendingText)
                    clipboard.setPrimaryClip(clip)
                    Toast.makeText(this, "✅ 백그라운드 텍스트 복사 완료", Toast.LENGTH_SHORT).show()
                } catch (e: Exception) {
                    Log.e("CopyActivity", "복사 권한 차단됨", e)
                }
            }
            // 작업 직후 무조건 창을 닫아 사용자 시야에서 소멸
            finish()
        }
    }
}
