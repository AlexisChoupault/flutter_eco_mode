package sncf.connect.tech.flutter_eco_mode

import android.content.ContentValues.TAG
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import sncf.connect.tech.flutter_eco_mode.listener.DisposableStreamListener

class FlutterEcoModePlugin: FlutterPlugin, ActivityAware {
    interface ActivityComponent {
        val requestPermissionsResultListener: PluginRegistry.RequestPermissionsResultListener
        val batteryLevelStreamListener: DisposableStreamListener
        val batteryStateStreamListener: DisposableStreamListener
        val powerModeStreamListener: DisposableStreamListener
        val connectivityStreamListener: DisposableStreamListener
        fun updateActivity(binding: ActivityPluginBinding?)
    }

    private val pluginScope = CoroutineScope(Dispatchers.Main + SupervisorJob() + CoroutineExceptionHandler { _, throwable ->
        Log.e(TAG, "EcoMode coroutine crash : ${throwable.message}", throwable)
    })

    private lateinit var activityComponent: ActivityComponent
    private var binding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val ecoModeImplem = EcoModeImplem(pluginScope, flutterPluginBinding.applicationContext)
        activityComponent = ecoModeImplem

        val binaryMessenger = flutterPluginBinding.binaryMessenger
        EcoModeApi.setUp(binaryMessenger, ecoModeImplem)
        activityComponent.batteryLevelStreamListener.register(binaryMessenger)
        activityComponent.batteryStateStreamListener.register(binaryMessenger)
        activityComponent.powerModeStreamListener.register(binaryMessenger)
        activityComponent.connectivityStreamListener.register(binaryMessenger)
    }

    override fun onDetachedFromEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        pluginScope.cancel()

        val binaryMessenger = flutterPluginBinding.binaryMessenger
        activityComponent.batteryLevelStreamListener.dispose(binaryMessenger)
        activityComponent.batteryStateStreamListener.dispose(binaryMessenger)
        activityComponent.powerModeStreamListener.dispose(binaryMessenger)
        activityComponent.connectivityStreamListener.dispose(binaryMessenger)
        EcoModeApi.setUp(binaryMessenger, null)
    }

    private fun attachToActivity(binding: ActivityPluginBinding) {
        this.binding = binding
        activityComponent.updateActivity(binding)
        binding.addRequestPermissionsResultListener(activityComponent.requestPermissionsResultListener)
    }

    private fun detachFromActivity() {
        binding?.removeRequestPermissionsResultListener(activityComponent.requestPermissionsResultListener)
        activityComponent.updateActivity(null)
        binding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) = attachToActivity(binding)
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = attachToActivity(binding)
    override fun onDetachedFromActivityForConfigChanges() = detachFromActivity()
    override fun onDetachedFromActivity() = detachFromActivity()
}
