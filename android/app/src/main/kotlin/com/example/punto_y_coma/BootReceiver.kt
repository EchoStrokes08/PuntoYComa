package com.example.punto_y_coma

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * After a phone reboot the OS clears our monitoring process but not the
 * securely stored trip. This receiver promotes the process to foreground
 * with the persistent notification only when a trip is armed (plain prefs
 * flag written from Dart); tapping it (or just opening the app) lets
 * TripController.tryResume() bring the alarm back to life.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "onReceive action=${intent.action}")
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        val prefs = context.getSharedPreferences(
            TripProtectionService.PREFS_NAME,
            Context.MODE_PRIVATE,
        )
        val armed = prefs.getBoolean(TripProtectionService.ARMED_KEY, false)
        Log.d(TAG, "armed flag read at boot: $armed")
        if (!armed) return
        val service = Intent(context, TripProtectionService::class.java)
        if (Build.VERSION.SDK_INT >= 26) {
            context.startForegroundService(service)
        } else {
            context.startService(service)
        }
        Log.d(TAG, "startForegroundService requested")
    }

    private companion object {
        const val TAG = "PuntoYcomaBoot"
    }
}
