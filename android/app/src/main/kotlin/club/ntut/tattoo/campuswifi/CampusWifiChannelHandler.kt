package club.ntut.tattoo.campuswifi

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class CampusWifiChannelHandler(
    private val activity: Activity,
) : MethodChannel.MethodCallHandler {
    companion object {
        private const val CHANNEL_NAME = "club.ntut.tattoo/campus_wifi"
    }

    private val provisioner by lazy { Ntut8021xProvisioner(activity.applicationContext) }

    private val wifiSettingsIntent: Intent
        get() = Intent(Settings.ACTION_WIFI_SETTINGS)

    private val wifiPanelIntent: Intent?
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            Intent(Settings.Panel.ACTION_WIFI)
        } else {
            null
        }

    fun register(binaryMessenger: BinaryMessenger) {
        MethodChannel(binaryMessenger, CHANNEL_NAME).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCapabilities" -> result.success(buildCapabilities())
            "openWifiSettings" -> result.success(openIntent(wifiSettingsIntent))
            "openWifiPanel" -> result.success(
                openIntent(wifiPanelIntent ?: wifiSettingsIntent),
            )
            "provisionNtut8021x" -> handleProvisionNtut8021xCall(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleProvisionNtut8021xCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val identity = call.argument<String>("identity")
        val password = call.argument<String>("password")
        if (identity.isNullOrBlank() || password.isNullOrBlank()) {
            result.error(
                "invalid_args",
                "identity and password are required",
                null,
            )
            return
        }

        result.success(provisioner.provisionNtut8021x(identity, password))
    }

    private fun buildCapabilities(): Map<String, Any?> {
        return mapOf(
            "sdkInt" to Build.VERSION.SDK_INT,
            "canOpenWifiSettings" to canResolve(wifiSettingsIntent),
            "canOpenWifiPanel" to canResolve(wifiPanelIntent),
            "canProvisionNtut8021x" to canProvisionNtut8021x(),
        )
    }

    private fun canProvisionNtut8021x(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && provisioner.canProvision()
    }

    private fun canResolve(intent: Intent?): Boolean {
        intent ?: return false
        return intent.resolveActivity(activity.packageManager) != null
    }

    private fun openIntent(intent: Intent?): Boolean {
        intent ?: return false
        if (!canResolve(intent)) return false

        return try {
            activity.startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }
}
