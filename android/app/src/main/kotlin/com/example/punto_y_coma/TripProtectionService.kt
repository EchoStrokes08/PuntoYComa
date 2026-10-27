package com.example.punto_y_coma

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/**
 * Keeps the armed-trip process alive as a location foreground service while
 * Flutter's monitors watch the route. It never owns the alarm logic: pure
 * process protection. Tapping the notification reopens the app, where
 * TripController.tryResume() restores monitoring from encrypted storage.
 */
class TripProtectionService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // The OS gives ~10 s to promote: do it first, in every path, or the
        // whole app process is killed with ForegroundServiceDidNotStartInTime.
        val promoted = promoteToForeground()
        android.util.Log.d(
            "TripProtection",
            "onStartCommand action=${intent?.action} promoted=$promoted",
        )
        if (intent?.action == ACTION_STOP) {
            stopForegroundCompat()
            stopSelf()
            return START_NOT_STICKY
        }
        return if (promoted) START_STICKY else START_NOT_STICKY
    }

    private fun promoteToForeground(): Boolean {
        try {
            val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= 26) {
                manager.createNotificationChannel(
                    NotificationChannel(
                        CHANNEL_ID,
                        "Vigilancia del viaje",
                        NotificationManager.IMPORTANCE_LOW,
                    )
                )
            }
            val tapIntent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra(RESUME_EXTRA, true)
            }
            val pending = PendingIntent.getActivity(
                this,
                0,
                tapIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            val builder =
                if (Build.VERSION.SDK_INT >= 26) {
                    Notification.Builder(this, CHANNEL_ID)
                } else {
                    @Suppress("DEPRECATION")
                    Notification.Builder(this)
                }
            val notification = builder
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("PuntoYcoma vigila tu viaje")
                .setContentText("Toca para retomar la vigilancia de tu parada.")
                .setOngoing(true)
                .setContentIntent(pending)
                .build()
            if (Build.VERSION.SDK_INT >= 29) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION,
                )
            } else {
                @Suppress("DEPRECATION")
                startForeground(NOTIFICATION_ID, notification)
            }
            return true
        } catch (denied: Exception) {
            // Without while-in-use location permission the promotion throws:
            // never take the app down for a protection nicety.
            android.util.Log.w(TAG, "Foreground promotion denied", denied)
            stopSelf()
            return false
        }
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= 33) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    companion object {
        const val CHANNEL_ID = "punto_y_coma.protection"
        const val NOTIFICATION_ID = 42
        const val ACTION_STOP = "com.puntoycoma.action.STOP"
        const val RESUME_EXTRA = "resume_from_notification"
        const val PREFS_NAME = "punto_y_coma_protection"
        const val ARMED_KEY = "armed"
        private const val TAG = "TripProtection"
    }
}
