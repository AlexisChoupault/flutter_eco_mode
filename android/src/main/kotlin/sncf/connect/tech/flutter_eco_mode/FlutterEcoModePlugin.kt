package sncf.connect.tech.flutter_eco_mode

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import sncf.connect.tech.flutter_eco_mode.listener.BatteryLevelListener
import sncf.connect.tech.flutter_eco_mode.listener.BatteryStateListener
import sncf.connect.tech.flutter_eco_mode.listener.ConnectivityStateListener
import sncf.connect.tech.flutter_eco_mode.listener.PowerModeListener

class FlutterEcoModePlugin : FlutterPlugin, ActivityAware {
    private lateinit var binaryMessenger: BinaryMessenger
    private var permissionHandler: PermissionHandler? = null
    private var activityBinding: ActivityPluginBinding? = null

    // FlutterPlugin implementation
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        binaryMessenger = flutterPluginBinding.binaryMessenger
    }

    override fun onDetachedFromEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        EcoModeApi.setUp(flutterPluginBinding.binaryMessenger, null)
    }

    // ActivityAware implementation
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        attachToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        attachToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachFromActivity()
    }

    // Private methods
    private fun attachToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        val context = binding.activity

        permissionHandler = PermissionHandler(context)
        val ecoModeImplem = EcoModeImplem(context, permissionHandler!!)

        binding.addRequestPermissionsResultListener(permissionHandler!!)
        EcoModeApi.setUp(binaryMessenger, ecoModeImplem)

        // Register stream handlers
        BatteryLevelStreamHandler.register(binaryMessenger, BatteryLevelListener(context))
        BatteryStateStreamHandler.register(binaryMessenger, BatteryStateListener(context))
        BatteryModeStreamHandler.register(binaryMessenger, PowerModeListener(context))
        ConnectivityStreamHandler.register(binaryMessenger, ConnectivityStateListener(context, permissionHandler!!))
    }

    private fun detachFromActivity() {
        permissionHandler?.let { handler ->
            activityBinding?.removeRequestPermissionsResultListener(handler)
        }

        EcoModeApi.setUp(binaryMessenger, null)

        val prefix = "dev.flutter.pigeon.flutter_eco_mode.EcoModeEventChannel"

        val channels = listOf(
            "$prefix.batteryLevel",
            "$prefix.batteryState",
            "$prefix.batteryMode",
            "$prefix.connectivity"
        )

        channels.forEach { channelName ->
            EventChannel(binaryMessenger, channelName, MessagesPigeonMethodCodec).setStreamHandler(null)
        }

        permissionHandler = null
        activityBinding = null
    }
}
