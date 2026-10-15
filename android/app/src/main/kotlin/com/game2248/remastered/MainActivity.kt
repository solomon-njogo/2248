package com.game2248.remastered

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.game2248.remastered/motor",
        ).setMethodCallHandler { call, result ->
            if (call.method != "pulse") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val millis = call.argument<Int>("millis") ?: 0
            val amplitude = call.argument<Int>("amplitude") ?: 255
            pulse(millis, amplitude)
            result.success(null)
        }
    }

    private fun pulse(millis: Int, amplitude: Int) {
        val vibrator = vibrator() ?: return
        if (!vibrator.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(
                VibrationEffect.createOneShot(
                    millis.toLong(),
                    amplitude.coerceIn(1, 255),
                ),
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(millis.toLong())
        }
    }

    private fun vibrator(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager =
                getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }
}
