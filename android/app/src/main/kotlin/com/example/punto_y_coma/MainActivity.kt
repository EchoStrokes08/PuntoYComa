package com.example.punto_y_coma

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "punto_y_coma/protection")
            .setMethodCallHandler { call, result ->
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
                    "updateProgress" -> {
                        if (!isArmed()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        val arguments = call.arguments as? Map<*, *>
                        val title = arguments?.get("title") as? String
                        val body = arguments?.get("body") as? String
                        val progress = (arguments?.get("progress") as? Number)?.toInt()
                        sendToService(
                            action = TripProtectionService.ACTION_UPDATE,
                            title = title,
                            body = body,
                            progress = progress,
                        )
                        result.success(true)
                    }
                    "clearProgress" -> {
                        // El viaje ya se desarmó: no se vuelve a iniciar el
                        // servicio solo para limpiar el texto.
                        if (!isArmed()) {
                            result.success(true)
                            return@setMethodCallHandler
                        }
                        sendToService(
                            action = TripProtectionService.ACTION_UPDATE,
                            title = null,
                            body = null,
                            progress = null,
                        )
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

        // Compartir texto plano (p. ej. el resumen del historial) sin añadir
        // dependencias de paquetes: la hoja nativa del sistema es suficiente.
        MethodChannel(messenger, "punto_y_coma/share")
            .setMethodCallHandler { call, result ->
                if (call.method != "shareText") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val text = (call.arguments as? Map<*, *>)?.get("text") as? String
                if (text.isNullOrBlank()) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                try {
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, text)
                    }
                    val chooser = Intent.createChooser(send, "Compartir resumen").apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(chooser)
                    result.success(true)
                } catch (error: Exception) {
                    android.util.Log.w("PuntoYcoma", "Share failed", error)
                    result.success(false)
                }
            }
    }

    private fun isArmed(): Boolean =
        getSharedPreferences(
            TripProtectionService.PREFS_NAME,
            MODE_PRIVATE,
        ).getBoolean(TripProtectionService.ARMED_KEY, false)

    /**
     * El servicio nativo debe promoverse a foreground en los primeros
     * segundos, así que cada actualización entra como `startForegroundService`:
     * `onStartCommand` llama a `startForeground` antes de leer los extras.
     */
    private fun sendToService(
        action: String,
        title: String?,
        body: String?,
        progress: Int?,
    ) {
        val intent = Intent(this, TripProtectionService::class.java).apply {
            this.action = action
            if (title != null) putExtra(TripProtectionService.EXTRA_TITLE, title)
            if (body != null) putExtra(TripProtectionService.EXTRA_BODY, body)
            putExtra(
                TripProtectionService.EXTRA_PROGRESS,
                progress ?: TripProtectionService.NO_PROGRESS,
            )
        }
        if (Build.VERSION.SDK_INT >= 26) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}
