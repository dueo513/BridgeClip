package com.antigravity.clipboardsync.clipboard_sync

import android.content.Intent
import android.service.quicksettings.TileService
import android.service.quicksettings.Tile
import android.os.Build

class SyncTileService : TileService() {
    override fun onStartListening() {
        super.onStartListening()
        val tile = qsTile
        tile?.state = Tile.STATE_INACTIVE
        tile?.updateTile()
    }

    override fun onClick() {
        super.onClick()
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("quick_sync", true)
        }
        
        // This launches the MainActivity while auto-closing the quick settings shade
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(android.app.PendingIntent.getActivity(this, 0, intent, android.app.PendingIntent.FLAG_IMMUTABLE))
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}
