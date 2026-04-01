package sncf.connect.tech.flutter_eco_mode

import android.Manifest.permission.ACCESS_NETWORK_STATE
import android.Manifest.permission.READ_BASIC_PHONE_STATE
import android.Manifest.permission.READ_PHONE_STATE
import android.app.Activity
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

class PermissionHandler : RequestPermissionsResultListener {
    var activity: Activity? = null
    private val callbacks = mutableMapOf<Int, (Boolean) -> Unit>()

    companion object {
        const val READ_PHONE_REQUEST_CODE = 1006
        const val NETWORK_STATE_REQUEST_CODE = 1007
    }

    // -------- Synchronous Checks --------

    fun hasNetworkStatePermission(): Boolean {
        val act = activity ?: return false
        return ActivityCompat.checkSelfPermission(act, ACCESS_NETWORK_STATE) == PERMISSION_GRANTED
    }

    fun hasReadPhoneStatePermission(): Boolean {
        val act = activity ?: return false
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
            READ_BASIC_PHONE_STATE else READ_PHONE_STATE
        return ActivityCompat.checkSelfPermission(act, permission) == PERMISSION_GRANTED
    }

    // -------- Asynchronous Requests --------

    suspend fun requestNetworkStatePermission(): Boolean = suspendCancellableCoroutine { continuation ->
        withActivity { activity ->
            if (hasNetworkStatePermission()) {
                continuation.resume(true)
            } else {
                callbacks[NETWORK_STATE_REQUEST_CODE] = { continuation.resume(it) }
                ActivityCompat.requestPermissions(activity, arrayOf(ACCESS_NETWORK_STATE), NETWORK_STATE_REQUEST_CODE)
            }
        }
    }

    suspend fun requestReadPhoneStatePermission(): Boolean = suspendCancellableCoroutine { continuation ->
        withActivity { activity ->
            if (hasReadPhoneStatePermission()) {
                continuation.resume(true)
            } else {
                val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
                    READ_BASIC_PHONE_STATE else READ_PHONE_STATE

                callbacks[READ_PHONE_REQUEST_CODE] = { continuation.resume(it) }
                ActivityCompat.requestPermissions(activity, arrayOf(permission), READ_PHONE_REQUEST_CODE)
            }
        }
    }

    // -------- Utils --------

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PERMISSION_GRANTED }
        callbacks.remove(requestCode)?.invoke(allGranted)
        return callbacks.containsKey(requestCode) // Retourne true si on a géré ce code
    }

    private fun withActivity(block: (Activity) -> Unit) {
        activity?.let { block(it) } ?: throw IllegalStateException("EcoMode Plugin: No linked Activity.")
    }
}
