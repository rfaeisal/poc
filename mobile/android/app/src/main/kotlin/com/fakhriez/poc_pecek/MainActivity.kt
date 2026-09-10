package com.fakhriez.poc_pecek

import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.os.PowerManager
import android.telephony.TelephonyManager
import android.view.KeyEvent
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val KIOSK_CHANNEL = "com.fakhriez.poc_ptx/kiosk"
        private const val KEY_EVENT_CHANNEL = "com.fakhriez.poc_ptx/key_events"
    }

    private var kioskEnabled = false
    private var keyEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KIOSK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableKiosk" -> {
                        enableKioskMode()
                        result.success(true)
                    }
                    "disableKiosk" -> {
                        disableKioskMode()
                        result.success(true)
                    }
                    "exitApp" -> {
                        disableKioskMode()
                        try { stopLockTask() } catch (_: Exception) {}
                        result.success(true)
                        window.decorView.postDelayed({
                            finishAndRemoveTask()
                            android.os.Process.killProcess(android.os.Process.myPid())
                        }, 300)
                    }
                    "pinApp" -> {
                        pinApp()
                        result.success(true)
                    }
                    "unpinApp" -> {
                        unpinApp()
                        result.success(true)
                    }
                    "bringToFront" -> {
                        bringAppToFront()
                        result.success(true)
                    }
                    "wakeScreen" -> {
                        wakeUpScreen()
                        result.success(true)
                    }
                    "keepScreenOn" -> {
                        val enable = call.argument<Boolean>("enable") ?: true
                        setKeepScreenOn(enable)
                        result.success(true)
                    }
                    "showOnLockScreen" -> {
                        showOnLockScreen()
                        result.success(true)
                    }
                    "getSignalStrength" -> {
                        result.success(getSignalDbm())
                    }
                    "maxVolume" -> {
                        setMaxVolume()
                        result.success(true)
                    }
                    "isKioskEnabled" -> {
                        result.success(kioskEnabled)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, KEY_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    keyEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    keyEventSink = null
                }
            })
    }

    private fun enableKioskMode() {
        kioskEnabled = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.let { controller ->
                controller.hide(WindowInsets.Type.systemBars())
                controller.systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                android.view.View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or android.view.View.SYSTEM_UI_FLAG_FULLSCREEN
                    or android.view.View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or android.view.View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or android.view.View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or android.view.View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun disableKioskMode() {
        kioskEnabled = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.show(WindowInsets.Type.systemBars())
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = android.view.View.SYSTEM_UI_FLAG_VISIBLE
        }
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun bringAppToFront() {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        am.moveTaskToFront(taskId, ActivityManager.MOVE_TASK_WITH_HOME)
    }

    @Suppress("DEPRECATION")
    private fun wakeUpScreen() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!pm.isInteractive) {
            val wakeLock = pm.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "pocptx:wakelock"
            )
            wakeLock.acquire(3000)
            wakeLock.release()
        }
    }

    private fun setKeepScreenOn(enable: Boolean) {
        if (enable) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    private fun showOnLockScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            km.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                    or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                    or WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }

    private fun getSignalDbm(): Int? {
        return try {
            val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val ss = tm.signalStrength
                ss?.cellSignalStrengths?.firstOrNull()?.dbm
            } else {
                null
            }
        } catch (_: Exception) { null }
    }

    private fun setMaxVolume() {
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val maxMedia = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        am.setStreamVolume(AudioManager.STREAM_MUSIC, maxMedia, 0)
        am.isSpeakerphoneOn = true
    }

    private fun pinApp() {
        try {
            startLockTask()
        } catch (_: Exception) {}
    }

    private fun unpinApp() {
        try {
            stopLockTask()
        } catch (_: Exception) {}
    }

    @Deprecated("Deprecated in API 33+")
    override fun onBackPressed() {
        if (kioskEnabled) return
        super.onBackPressed()
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        keyEventSink?.success(
            mapOf(
                "keyCode" to event.keyCode,
                "action" to event.action,
                "scanCode" to event.scanCode
            )
        )
        return super.dispatchKeyEvent(event)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus && kioskEnabled) {
            enableKioskMode()
        }
    }
}
