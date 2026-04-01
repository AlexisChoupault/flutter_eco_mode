package sncf.connect.tech.flutter_eco_mode

import android.content.BroadcastReceiver
import android.content.ContentValues.TAG
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager.BATTERY_STATUS_CHARGING
import android.os.BatteryManager.BATTERY_STATUS_DISCHARGING
import android.os.BatteryManager.BATTERY_STATUS_FULL
import android.os.BatteryManager.BATTERY_STATUS_NOT_CHARGING
import android.os.BatteryManager.EXTRA_LEVEL
import android.os.BatteryManager.EXTRA_SCALE
import android.os.BatteryManager.EXTRA_STATUS
import android.os.PowerManager
import android.util.Log

class EcoBatteryManager(private val context: Context) {
    private val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager

    fun getBatteryLevel(): Double {
        val batteryStatusIntent = registerBatteryReceiver()
        return parseLevel(batteryStatusIntent)
    }

    fun getBatteryState(): BatteryState {
        val batteryStatusIntent = registerBatteryReceiver()
        return parseState(batteryStatusIntent)
    }

    fun parseLevel(intent: Intent?): Double {
        val level = intent?.getIntExtra(EXTRA_LEVEL, -1) ?: -1
        val scale = intent?.getIntExtra(EXTRA_SCALE, -1) ?: -1

        return if (level != -1 && scale > 0) {
            (level.toDouble() / scale.toDouble()) * 100.0
        } else 0.0
    }

    fun parseState(intent: Intent?): BatteryState {
        val status = intent?.getIntExtra(EXTRA_STATUS, -1) ?: -1
        return when (status) {
            BATTERY_STATUS_CHARGING -> BatteryState.CHARGING
            BATTERY_STATUS_FULL -> BatteryState.FULL

            BATTERY_STATUS_DISCHARGING,
            BATTERY_STATUS_NOT_CHARGING -> BatteryState.DISCHARGING
            else -> BatteryState.UNKNOWN
        }
    }

    fun isLowPowerMode(): Boolean = powerManager.isPowerSaveMode

    fun registerBatteryReceiver(broadcastReceiver: BroadcastReceiver? = null): Intent? {
        return context.registerReceiver(broadcastReceiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
    }

    fun registerPowerModeReceiver(broadcastReceiver: BroadcastReceiver?): Intent? {
        return context.registerReceiver(broadcastReceiver, IntentFilter(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED))
    }

    fun unregisterReceiver(broadcastReceiver: BroadcastReceiver) {
        try {
            context.unregisterReceiver(broadcastReceiver)
        } catch (_: IllegalArgumentException) {
            Log.w(TAG, "Receiver was not registered")
        }
    }
}
