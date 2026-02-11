package sncf.connect.tech.flutter_eco_mode.listener

import android.content.BroadcastReceiver
import android.content.ContentValues.TAG
import android.content.Context
import android.content.Intent
import android.content.Intent.ACTION_BATTERY_CHANGED
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.BatteryManager.BATTERY_STATUS_CHARGING
import android.os.BatteryManager.BATTERY_STATUS_DISCHARGING
import android.os.BatteryManager.BATTERY_STATUS_FULL
import android.os.BatteryManager.BATTERY_STATUS_NOT_CHARGING
import android.util.Log
import sncf.connect.tech.flutter_eco_mode.BatteryState
import sncf.connect.tech.flutter_eco_mode.BatteryState.CHARGING
import sncf.connect.tech.flutter_eco_mode.BatteryState.DISCHARGING
import sncf.connect.tech.flutter_eco_mode.BatteryState.FULL
import sncf.connect.tech.flutter_eco_mode.BatteryState.UNKNOWN
import sncf.connect.tech.flutter_eco_mode.BatteryStateStreamHandler
import sncf.connect.tech.flutter_eco_mode.PigeonEventSink

class BatteryStateListener(private val context: Context) : BatteryStateStreamHandler() {
    private var batteryStateEventSink: PigeonEventSink<BatteryState>? = null
    private var batteryStateReceiver: BroadcastReceiver? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<BatteryState>) {
        batteryStateEventSink = sink

        setupBatteryStateReceiver()
    }

    override fun onCancel(p0: Any?) {
        batteryStateReceiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (_: IllegalArgumentException) {
                Log.w(TAG, "Receiver already unregistered")
            }
        }

        batteryStateReceiver = null
        batteryStateEventSink = null
    }

    private fun setupBatteryStateReceiver() {
        batteryStateReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent?) {
                val event = when (intent?.action) {
                    ACTION_BATTERY_CHANGED ->
                        when (intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)) {
                            BATTERY_STATUS_CHARGING -> CHARGING
                            BATTERY_STATUS_FULL -> FULL
                            BATTERY_STATUS_DISCHARGING, BATTERY_STATUS_NOT_CHARGING -> DISCHARGING
                            else -> UNKNOWN
                        }

                    else -> DISCHARGING
                }
                batteryStateEventSink?.success(event)
            }
        }
        val filterBatteryState = IntentFilter()
        filterBatteryState.addAction(ACTION_BATTERY_CHANGED)
        context.registerReceiver(batteryStateReceiver, filterBatteryState)
    }
}
