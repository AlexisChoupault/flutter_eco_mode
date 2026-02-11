package sncf.connect.tech.flutter_eco_mode.listener

import android.content.BroadcastReceiver
import android.content.ContentValues.TAG
import android.content.Context
import android.net.ConnectivityManager
import android.net.ConnectivityManager.NetworkCallback
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkCapabilities.TRANSPORT_CELLULAR
import android.net.NetworkCapabilities.TRANSPORT_ETHERNET
import android.net.NetworkCapabilities.TRANSPORT_WIFI
import android.os.Handler
import android.os.Looper
import android.telephony.TelephonyManager
import android.util.Log
import sncf.connect.tech.flutter_eco_mode.Connectivity
import sncf.connect.tech.flutter_eco_mode.ConnectivityType
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.ETHERNET
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.NONE
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.UNKNOWN
import sncf.connect.tech.flutter_eco_mode.ConnectivityType.WIFI
import sncf.connect.tech.flutter_eco_mode.ConnectivityStreamHandler
import sncf.connect.tech.flutter_eco_mode.PermissionHandler
import sncf.connect.tech.flutter_eco_mode.PigeonEventSink
import sncf.connect.tech.flutter_eco_mode.getWifiSignalStrength
import sncf.connect.tech.flutter_eco_mode.networkType

class ConnectivityStateListener(
    private val context: Context,
    private val permissionHandler: PermissionHandler,
) : ConnectivityStreamHandler() {
    private val mainHandler: Handler = Handler(Looper.getMainLooper())
    private val connectivityManager: ConnectivityManager = context.getSystemService(ConnectivityManager::class.java)
    private val telephonyManager: TelephonyManager = context.getSystemService(TelephonyManager::class.java)

    private var networkCallback: NetworkCallback? = null
    private var eventSink: PigeonEventSink<Connectivity>? = null
    private var connectivityStateReceiver: BroadcastReceiver? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<Connectivity>) {
        eventSink = sink
        networkCallback = object : NetworkCallback() {
            override fun onAvailable(network: Network) {
                Log.d(TAG, "The default network is now: $network")
                sendEvent(
                    networkCapabilities = connectivityManager.getNetworkCapabilities(network),
                    telephonyManager = telephonyManager
                )
            }

            override fun onCapabilitiesChanged(
                network: Network,
                networkCapabilities: NetworkCapabilities
            ) {
                Log.d(TAG, "The default network changed capabilities: $networkCapabilities")
                sendEvent(
                    networkCapabilities = networkCapabilities,
                    telephonyManager = telephonyManager
                )
            }

            override fun onLost(network: Network) {
                Log.d(TAG, "Network lost, the last default network was $network")
                sendEvent(
                    networkCapabilities = connectivityManager.getNetworkCapabilities(network),
                    telephonyManager = telephonyManager
                )
            }
        }

        connectivityManager.registerDefaultNetworkCallback(networkCallback as NetworkCallback)

        sendEvent(telephonyManager = telephonyManager)
    }

    override fun onCancel(p0: Any?) {
        networkCallback?.let {
            try {
                connectivityManager.unregisterNetworkCallback(it)
            } catch (e: Exception) {
                Log.e(TAG, "Erreur lors du unregisterNetworkCallback", e)
            }
        }

        connectivityStateReceiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (e: Exception) {
                Log.e(TAG, "Erreur lors du unregisterReceiver", e)
            }
        }

        networkCallback = null
        connectivityStateReceiver = null
        eventSink = null

        mainHandler.removeCallbacksAndMessages(null)
    }

    private fun sendEvent(
        networkCapabilities: NetworkCapabilities? = null,
        telephonyManager: TelephonyManager,
    ) {
        val networkType = getNetworkType(networkCapabilities, telephonyManager)
        val wifiSignalStrength = networkCapabilities?.getWifiSignalStrength(context)

        // Emit events on main thread
        mainHandler.post {
            eventSink?.success(
                Connectivity(
                    type = networkType,
                    wifiSignalStrength = wifiSignalStrength
                )
            )
        }
    }

    private fun getNetworkType(
        networkCapabilities: NetworkCapabilities?,
        telephonyManager: TelephonyManager
    ): ConnectivityType {
        return when {
            networkCapabilities?.hasTransport(TRANSPORT_ETHERNET) == true -> ETHERNET
            networkCapabilities?.hasTransport(TRANSPORT_WIFI) == true -> WIFI
            networkCapabilities?.hasTransport(TRANSPORT_CELLULAR) == true -> {
                if (permissionHandler.hasReadPhoneStatePermission()) {
                    try {
                        telephonyManager.networkType()
                    } catch (e: SecurityException) {
                        Log.e(TAG, "SecurityException while accessing network type: ${e.message}")
                        UNKNOWN
                    }

                } else {
                    Log.w(TAG, "READ_PHONE_STATE permission not granted. Returning UNKNOWN for cellular network type.")
                    UNKNOWN
                }
            }
            else -> NONE
        }
    }
}
