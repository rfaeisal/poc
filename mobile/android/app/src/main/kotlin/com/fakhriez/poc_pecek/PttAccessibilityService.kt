package com.fakhriez.poc_pecek

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent

class PttAccessibilityService : AccessibilityService() {

    companion object {
        var isRunning = false
            private set
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isRunning = true
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}

    override fun onInterrupt() {}

    override fun onKeyEvent(event: KeyEvent): Boolean {
        if (event.action != KeyEvent.ACTION_DOWN) return false
        if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
            event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN ||
            event.keyCode == KeyEvent.KEYCODE_POWER) return false

        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!pm.isInteractive) {
            @Suppress("DEPRECATION")
            val wakeLock = pm.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "pocptx:ptt-accessibility-wake"
            )
            wakeLock.acquire(5000)
            wakeLock.release()

            val intent = Intent(this, MainActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                )
            }
            startActivity(intent)
        }
        return false
    }

    override fun onDestroy() {
        isRunning = false
        super.onDestroy()
    }
}
