package sncf.connect.tech.flutter_eco_mode.listener

import android.content.BroadcastReceiver
import android.content.ContentValues.TAG
import android.util.Log
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.PowerManager
import sncf.connect.tech.flutter_eco_mode.BatteryModeStreamHandler
import sncf.connect.tech.flutter_eco_mode.PigeonEventSink

class PowerModeListener(private val context: Context) : BatteryModeStreamHandler() {
    private var lowPowerModeEventSink: PigeonEventSink<Boolean>? = null
    private var powerSavingReceiver: BroadcastReceiver? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<Boolean>) {
        lowPowerModeEventSink = sink
        setupPowerSavingReceiver()

        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        sink.success(powerManager.isPowerSaveMode)
    }

    override fun onCancel(p0: Any?) {
        powerSavingReceiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (_: IllegalArgumentException) {
                Log.w(TAG, "Receiver already unregistered")
            }
        }
        powerSavingReceiver = null
        lowPowerModeEventSink = null
    }

    private fun setupPowerSavingReceiver() {
        if (powerSavingReceiver != null) return

        powerSavingReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent?) {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                lowPowerModeEventSink?.success(powerManager.isPowerSaveMode)
            }
        }
        val filter = IntentFilter(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED)
        context.registerReceiver(powerSavingReceiver, filter)
    }
}
