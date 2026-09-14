package com.fakhriez.poc_pecek

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log

class MeigKeyReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val extras = intent.extras
        val info = extras?.keySet()?.joinToString { "$it=${extras.get(it)}" } ?: "no extras"
        Log.w("PttMeigKey", "static receiver: $info")

        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!pm.isInteractive) {
            @Suppress("DEPRECATION")
            val wakeLock = pm.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "pocptx:meig-wake"
            )
            wakeLock.acquire(5000)
            wakeLock.release()

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                )
            }
            context.startActivity(launchIntent)
        }
    }
}
