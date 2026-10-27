package com.example.punto_y_coma

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "punto_y_coma/protection",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForeground" -> {
                    val service = Intent(this, TripProtectionService::class.java)
                    if (Build.VERSION.SDK_INT >= 26) {
                        startForegroundService(service)
                    } else {
                        startService(service)
                    }
                    result.success(true)
                }
                "stopForeground" -> {
                    stopService(Intent(this, TripProtectionService::class.java))
                    result.success(true)
                }
                "setArmedFlag" -> {
                    val arguments = call.arguments as? Map<*, *>
                    val armed = arguments?.get("armed") as? Boolean == true
                    getSharedPreferences(
                        TripProtectionService.PREFS_NAME,
                        MODE_PRIVATE,
                    ).edit().putBoolean(TripProtectionService.ARMED_KEY, armed).apply()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
