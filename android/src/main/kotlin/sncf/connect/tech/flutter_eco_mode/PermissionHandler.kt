package sncf.connect.tech.flutter_eco_mode

import android.Manifest.permission.READ_BASIC_PHONE_STATE
import android.Manifest.permission.READ_PHONE_STATE
import android.app.Activity
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener

/**
 * Handler for plugin permissions.
 * Handles requesting and checking READ_PHONE_STATE or READ_BASIC_PHONE_STATE permission.
 * Should be used in conjunction with ActivityPluginBinding.addRequestPermissionsResultListener.
 */
class PermissionHandler(private val activity: Activity): RequestPermissionsResultListener {
    private var permissionCallback: (Boolean) -> Unit = {}

    companion object {
        const val REQUEST_CODE = 1006
    }

    /**
     * Handle the result of a permission request.
     * Should be called from onRequestPermissionsResult.
     * @return true if this handler handled the request code
     */
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == REQUEST_CODE) {
            val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PERMISSION_GRANTED }
            permissionCallback(allGranted)
            return true
        }
        return false
    }

    /**
     * Request READ_PHONE_STATE or READ_BASIC_PHONE_STATE permission.
     * @param callback Called with true if permission is granted, false otherwise.
     */
    fun requestReadPhoneStatePermission(callback: (Boolean) -> Unit) {
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) READ_BASIC_PHONE_STATE else READ_PHONE_STATE

        if (hasPermission(permission)) {
            callback(true)
        } else if (shouldRequestPermissionRationale(permission)) {
            permissionCallback = callback
            ActivityCompat.requestPermissions(activity, arrayOf(permission), REQUEST_CODE)
        } else {
            callback(false)
        }
    }

    fun hasReadPhoneStatePermission(): Boolean {
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) READ_BASIC_PHONE_STATE else READ_PHONE_STATE
        return hasPermission(permission)
    }

    private fun hasPermission(permission: String): Boolean = ActivityCompat.checkSelfPermission( activity, permission) == PERMISSION_GRANTED

    private fun shouldRequestPermissionRationale(permission: String): Boolean = ActivityCompat.shouldShowRequestPermissionRationale(activity, permission)
}
