package com.fakhriez.poc_pecek

import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.PowerManager
import android.net.wifi.WifiManager
import android.telephony.TelephonyManager
import android.view.KeyEvent
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile

class MainActivity : FlutterActivity() {
    companion object {
        private const val KIOSK_CHANNEL = "com.fakhriez.poc_ptx/kiosk"
        private const val KEY_EVENT_CHANNEL = "com.fakhriez.poc_ptx/key_events"
    }

    private var kioskEnabled = false
    private var keyEventSink: EventChannel.EventSink? = null
    private var mediaSession: MediaSession? = null
    private var meigKeyReceiver: BroadcastReceiver? = null
    private var pttChannel: MethodChannel? = null
    private var pttKeyCode: Int = 142

    private var audioRecord: AudioRecord? = null
    private var recordingThread: Thread? = null
    @Volatile private var isRecording = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        pttChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.fakhriez.poc_ptx/ptt_native")
        pttChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setPttKeyCode" -> {
                    pttKeyCode = call.argument<Int>("keyCode") ?: 293
                    Log.w("PttNative", "PTT keyCode set to $pttKeyCode")
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

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
                    "ensureAudioOutput" -> {
                        ensureAudioOutput()
                        result.success(true)
                    }
                    "isAccessibilityEnabled" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        })
                        result.success(true)
                    }
                    "isKioskEnabled" -> {
                        result.success(kioskEnabled)
                    }
                    "startRecording" -> {
                        val path = call.argument<String>("path")
                        if (path != null) {
                            startNativeRecording(path)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARG", "path required", null)
                        }
                    }
                    "stopRecording" -> {
                        stopNativeRecording()
                        result.success(true)
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

        mediaSession = MediaSession(this, "PocPtt").apply {
            setPlaybackState(
                PlaybackState.Builder()
                    .setState(PlaybackState.STATE_PLAYING, 0, 1.0f)
                    .setActions(PlaybackState.ACTION_PLAY or PlaybackState.ACTION_PAUSE)
                    .build()
            )
            setCallback(object : MediaSession.Callback() {
                override fun onMediaButtonEvent(mediaButtonEvent: Intent): Boolean {
                    val ke = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        mediaButtonEvent.getParcelableExtra(Intent.EXTRA_KEY_EVENT, KeyEvent::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        mediaButtonEvent.getParcelableExtra<KeyEvent>(Intent.EXTRA_KEY_EVENT)
                    }
                    if (ke != null) {
                        ensureScreenOn()
                        keyEventSink?.success(mapOf(
                            "keyCode" to ke.keyCode,
                            "action" to ke.action,
                            "scanCode" to ke.scanCode
                        ))
                    }
                    return true
                }
            })
            isActive = true
        }

        meigKeyReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val extras = intent.extras
                val info = extras?.keySet()?.joinToString { "$it=${extras.get(it)}" } ?: "no extras"
                Log.w("PttMeigKey", "broadcast received: $info")

                val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                if (!pm.isInteractive) {
                    ensureScreenOn()
                }

                val action = extras?.getInt("action", -1) ?: -1
                if (action == KeyEvent.ACTION_DOWN) {
                    Log.w("PttMeigKey", "PTT DOWN via Meig broadcast")
                    pttChannel?.invokeMethod("pttDown", null)
                } else if (action == KeyEvent.ACTION_UP) {
                    Log.w("PttMeigKey", "PTT UP via Meig broadcast")
                    pttChannel?.invokeMethod("pttUp", null)
                }
            }
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                applicationContext.registerReceiver(
                    meigKeyReceiver,
                    IntentFilter("com.meigsmart.meigkeyaccessibility.onkeyevent"),
                    Context.RECEIVER_EXPORTED
                )
            } else {
                applicationContext.registerReceiver(
                    meigKeyReceiver,
                    IntentFilter("com.meigsmart.meigkeyaccessibility.onkeyevent")
                )
            }
            Log.w("PttMeigKey", "dynamic receiver registered")
        } catch (e: Exception) {
            Log.e("PttMeigKey", "failed to register: ${e.message}")
        }
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

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expected = ComponentName(this, PttAccessibilityService::class.java)
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServices)
        while (colonSplitter.hasNext()) {
            val name = colonSplitter.next()
            val cn = ComponentName.unflattenFromString(name)
            if (cn != null && cn == expected) return true
        }
        return false
    }

    private fun ensureScreenOn() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!pm.isInteractive) {
            wakeUpScreen()
            showOnLockScreen()
            bringAppToFront()
        }
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
            val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            @Suppress("DEPRECATION")
            val rssi = wm.connectionInfo.rssi
            if (rssi != -127) rssi else null
        } catch (_: Exception) {
            try {
                val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    tm.signalStrength?.cellSignalStrengths?.firstOrNull()?.dbm
                } else null
            } catch (_: Exception) { null }
        }
    }

    private fun setMaxVolume() {
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val maxMedia = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        am.setStreamVolume(AudioManager.STREAM_MUSIC, maxMedia, 0)
        am.isSpeakerphoneOn = true
    }

    private fun ensureAudioOutput() {
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        am.mode = AudioManager.MODE_IN_COMMUNICATION
        am.isSpeakerphoneOn = true
        // Sync VOICE_CALL volume to match MUSIC volume ratio set by user
        val musicVol = am.getStreamVolume(AudioManager.STREAM_MUSIC)
        val musicMax = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val voiceMax = am.getStreamMaxVolume(AudioManager.STREAM_VOICE_CALL)
        val ratio = if (musicMax > 0) musicVol.toFloat() / musicMax else 0.5f
        am.setStreamVolume(AudioManager.STREAM_VOICE_CALL, (voiceMax * ratio).toInt().coerceAtLeast(1), 0)
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
        Log.w("PttNative", "dispatchKeyEvent keyCode=${event.keyCode} action=${event.action} repeat=${event.repeatCount}")

        if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
            event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
                val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val direction = if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP)
                    AudioManager.ADJUST_RAISE else AudioManager.ADJUST_LOWER
                am.adjustStreamVolume(
                    AudioManager.STREAM_MUSIC, direction, AudioManager.FLAG_SHOW_UI
                )
            }
            return true
        }

        if (event.action == KeyEvent.ACTION_DOWN) {
            ensureScreenOn()
        }

        if (event.keyCode == pttKeyCode) {
            if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
                Log.w("PttNative", "PTT DOWN via native, invoking Flutter")
                pttChannel?.invokeMethod("pttDown", null)
            } else if (event.action == KeyEvent.ACTION_UP) {
                Log.w("PttNative", "PTT UP via native, invoking Flutter")
                pttChannel?.invokeMethod("pttUp", null)
            }
        }

        keyEventSink?.success(
            mapOf(
                "keyCode" to event.keyCode,
                "action" to event.action,
                "scanCode" to event.scanCode
            )
        )
        return super.dispatchKeyEvent(event)
    }

    override fun onDestroy() {
        mediaSession?.release()
        mediaSession = null
        try { meigKeyReceiver?.let { applicationContext.unregisterReceiver(it) } } catch (_: Exception) {}
        meigKeyReceiver = null
        super.onDestroy()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus && kioskEnabled) {
            enableKioskMode()
        }
    }

    private fun startNativeRecording(path: String) {
        stopNativeRecording()

        val sampleRate = 16000
        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val audioFormat = AudioFormat.ENCODING_PCM_16BIT
        val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
            .coerceAtLeast(4096)

        try {
            val rec = AudioRecord(
                MediaRecorder.AudioSource.VOICE_COMMUNICATION,
                sampleRate, channelConfig, audioFormat, bufferSize * 2
            )
            if (rec.state == AudioRecord.STATE_INITIALIZED) {
                audioRecord = rec
            } else {
                rec.release()
            }
        } catch (_: Exception) {}

        if (audioRecord == null) {
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate, channelConfig, audioFormat, bufferSize * 2
            )
        }

        isRecording = true
        audioRecord?.startRecording()

        recordingThread = Thread {
            val file = File(path)
            val fos = FileOutputStream(file)
            // Write WAV header placeholder (44 bytes)
            fos.write(ByteArray(44))

            val buffer = ShortArray(bufferSize / 2)
            var totalBytes = 0L

            while (isRecording) {
                val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                if (read > 0) {
                    val byteBuffer = ByteArray(read * 2)
                    for (i in 0 until read) {
                        byteBuffer[i * 2] = (buffer[i].toInt() and 0xFF).toByte()
                        byteBuffer[i * 2 + 1] = (buffer[i].toInt() shr 8 and 0xFF).toByte()
                    }
                    fos.write(byteBuffer)
                    totalBytes += byteBuffer.size
                }
            }
            fos.close()

            // Write actual WAV header
            val raf = RandomAccessFile(file, "rw")
            writeWavHeader(raf, totalBytes, sampleRate)
            raf.close()
        }
        recordingThread?.start()
    }

    private fun stopNativeRecording() {
        isRecording = false
        recordingThread?.join(3000)
        recordingThread = null
        try {
            audioRecord?.stop()
            audioRecord?.release()
        } catch (_: Exception) {}
        audioRecord = null
    }

    private fun writeWavHeader(raf: RandomAccessFile, pcmSize: Long, sampleRate: Int) {
        val channels = 1
        val bitsPerSample = 16
        val byteRate = sampleRate * channels * bitsPerSample / 8
        val blockAlign = channels * bitsPerSample / 8

        raf.seek(0)
        raf.writeBytes("RIFF")
        raf.write(intToLEBytes((36 + pcmSize).toInt()))
        raf.writeBytes("WAVE")
        raf.writeBytes("fmt ")
        raf.write(intToLEBytes(16))
        raf.write(shortToLEBytes(1))
        raf.write(shortToLEBytes(channels.toShort()))
        raf.write(intToLEBytes(sampleRate))
        raf.write(intToLEBytes(byteRate))
        raf.write(shortToLEBytes(blockAlign.toShort()))
        raf.write(shortToLEBytes(bitsPerSample.toShort()))
        raf.writeBytes("data")
        raf.write(intToLEBytes(pcmSize.toInt()))
    }

    private fun intToLEBytes(v: Int): ByteArray = byteArrayOf(
        (v and 0xFF).toByte(), (v shr 8 and 0xFF).toByte(),
        (v shr 16 and 0xFF).toByte(), (v shr 24 and 0xFF).toByte()
    )

    private fun shortToLEBytes(v: Short): ByteArray = byteArrayOf(
        (v.toInt() and 0xFF).toByte(), (v.toInt() shr 8 and 0xFF).toByte()
    )
}
