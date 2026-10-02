package com.thehummingbirdstudio.vepari

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createUpdatesChannel()
    }

    // Pushes from push-dispatch name this channel (android.notification.channel_id).
    // Creating it again is harmless and refreshes its name after a language change.
    private fun createUpdatesChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            "vepari_updates",
            getString(R.string.notification_channel_updates),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply { description = getString(R.string.notification_channel_updates_description) }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }
}
