package sncf.connect.tech.flutter_eco_mode.listener

import android.content.BroadcastReceiver
import android.content.ContentValues.TAG
import android.content.Context
import android.content.Intent
import android.content.Intent.ACTION_BATTERY_CHANGED
import android.content.IntentFilter
import android.os.BatteryManager
import android.util.Log
import sncf.connect.tech.flutter_eco_mode.BatteryLevelStreamHandler
import sncf.connect.tech.flutter_eco_mode.PigeonEventSink

class BatteryLevelListener(private val context: Context) : BatteryLevelStreamHandler() {
    private var batteryLevelEventSink: PigeonEventSink<Double>? = null
    private var batteryLevelReceiver: BroadcastReceiver? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<Double>) {
        batteryLevelEventSink = sink

        setupBatteryLevelReceiver()
    }

    override fun onCancel(p0: Any?) {
        batteryLevelReceiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (_: IllegalArgumentException) {
                Log.w(TAG, "Receiver already unregistered")
            }
        }

        batteryLevelReceiver = null
        batteryLevelEventSink = null
    }

    private fun setupBatteryLevelReceiver() {
        batteryLevelReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent?) {
                val batteryPct = intent?.let { i ->
                    val level: Int = i.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                    val scale: Int = i.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                    level * 100 / scale.toFloat()
                }
                batteryPct?.toDouble()?.let { batteryLevelEventSink?.success(it) }
            }
        }
        val filter = IntentFilter(ACTION_BATTERY_CHANGED)
        context.registerReceiver(batteryLevelReceiver, filter)
    }
}
