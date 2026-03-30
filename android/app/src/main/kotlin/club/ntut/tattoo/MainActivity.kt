package club.ntut.tattoo

import android.annotation.SuppressLint
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.wifi.WifiEnterpriseConfig
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSuggestion
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.lang.reflect.InvocationTargetException
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

class MainActivity : FlutterActivity() {
    companion object {
        private const val CAMPUS_WIFI_CHANNEL = "club.ntut.tattoo/campus_wifi"
        private const val NTUT_8021X_SSID = "NTUT-802.1X"
        private const val NTUT_DOMAIN_SUFFIX = "ntut.edu.tw"
        private const val SYSTEM_CA_CERT_PATH = "/system/etc/security/cacerts"
        private const val APPROVAL_STATUS_TIMEOUT_MS = 500L
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CAMPUS_WIFI_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCapabilities" -> result.success(buildCapabilities())

                "openWifiSettings" -> result.success(openIntent(Intent(Settings.ACTION_WIFI_SETTINGS)))
                "openWifiPanel" -> result.success(
                    openIntent(wifiPanelIntent ?: Intent(Settings.ACTION_WIFI_SETTINGS)),
                )

                "provisionNtut8021x" -> {
                    val identity = call.argument<String>("identity")
                    val password = call.argument<String>("password")
                    if (identity.isNullOrBlank() || password.isNullOrBlank()) {
                        result.error(
                            "invalid_args",
                            "identity and password are required",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    result.success(provisionNtut8021x(identity, password))
                }

                else -> result.notImplemented()
            }
        }
    }

    private val wifiPanelIntent: Intent?
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            Intent(Settings.Panel.ACTION_WIFI)
        } else {
            null
        }

    private fun buildCapabilities(): Map<String, Any?> {
        return mapOf(
            "sdkInt" to Build.VERSION.SDK_INT,
            "canOpenWifiSettings" to canResolve(Intent(Settings.ACTION_WIFI_SETTINGS)),
            "canOpenWifiPanel" to canResolve(wifiPanelIntent),
            "canProvisionNtut8021x" to canProvisionNtut8021x(),
        )
    }

    private fun canProvisionNtut8021x(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && wifiManager != null
    }

    private val wifiManager: WifiManager?
        get() = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager

    @SuppressLint("MissingPermission")
    private fun provisionNtut8021x(identity: String, password: String): Map<String, Any?> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return buildProvisioningResult(status = "unsupportedPlatform")
        }

        val wifiManager = wifiManager
            ?: return buildProvisioningResult(status = "unsupportedPlatform")
        val wifiEnabled = wifiManager.isWifiEnabled

        val enterpriseConfig = WifiEnterpriseConfig().apply {
            eapMethod = WifiEnterpriseConfig.Eap.PEAP
            phase2Method = WifiEnterpriseConfig.Phase2.GTC
            setIdentity(identity)
            setPassword(password)
            setDomainSuffixMatch(NTUT_DOMAIN_SUFFIX)
        }

        val usedHiddenCaPath = enableSystemCertificateValidation(enterpriseConfig)
        if (!usedHiddenCaPath) {
            return buildProvisioningResult(
                status = "validationUnavailable",
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = false,
            )
        }

        val suggestion = try {
            WifiNetworkSuggestion.Builder()
                .setSsid(NTUT_8021X_SSID)
                .setWpa2EnterpriseConfig(enterpriseConfig)
                .setCredentialSharedWithUser(true)
                .setIsInitialAutojoinEnabled(true)
                .build()
        } catch (_: IllegalArgumentException) {
            return buildProvisioningResult(
                status = "validationUnavailable",
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = true,
            )
        } catch (error: RuntimeException) {
            return buildProvisioningResult(
                status = "failed",
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = true,
                message = error.message,
            )
        }

        val suggestionStatus = try {
            wifiManager.addNetworkSuggestions(listOf(suggestion))
        } catch (error: SecurityException) {
            return buildProvisioningResult(
                status = "failed",
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = true,
                message = error.message,
            )
        } catch (error: IllegalArgumentException) {
            return buildProvisioningResult(
                status = "validationUnavailable",
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = true,
                message = error.message,
            )
        } catch (error: RuntimeException) {
            return buildProvisioningResult(
                status = "failed",
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = true,
                message = error.message,
            )
        }

        val approvalStatus = getSuggestionApprovalStatus(wifiManager)
        return when (suggestionStatus) {
            WifiManager.STATUS_NETWORK_SUGGESTIONS_SUCCESS,
            WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_ADD_DUPLICATE,
            -> buildProvisioningResult(
                status = if (wifiEnabled) "success" else "successPendingWifi",
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = true,
                networkSuggestionStatus = suggestionStatus,
                approvalStatus = approvalStatus,
            )

            WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_APP_DISALLOWED -> buildProvisioningResult(
                status = when (approvalStatus) {
                    WifiManager.STATUS_SUGGESTION_APPROVAL_REJECTED_BY_USER -> "approvalRejected"
                    else -> "approvalPending"
                },
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = true,
                networkSuggestionStatus = suggestionStatus,
                approvalStatus = approvalStatus,
            )

            WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_RESTRICTED_BY_ADMIN -> buildProvisioningResult(
                status = "failed",
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = true,
                networkSuggestionStatus = suggestionStatus,
                approvalStatus = approvalStatus,
                message = "restricted_by_admin",
            )

            WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_ADD_INVALID -> buildProvisioningResult(
                status = "validationUnavailable",
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = true,
                networkSuggestionStatus = suggestionStatus,
                approvalStatus = approvalStatus,
            )

            else -> buildProvisioningResult(
                status = "failed",
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = true,
                networkSuggestionStatus = suggestionStatus,
                approvalStatus = approvalStatus,
            )
        }
    }

    private fun enableSystemCertificateValidation(
        enterpriseConfig: WifiEnterpriseConfig,
    ): Boolean {
        return try {
            val method = WifiEnterpriseConfig::class.java.getMethod(
                "setCaPath",
                String::class.java,
            )
            method.isAccessible = true
            method.invoke(enterpriseConfig, SYSTEM_CA_CERT_PATH)
            true
        } catch (_: NoSuchMethodException) {
            false
        } catch (_: IllegalAccessException) {
            false
        } catch (_: InvocationTargetException) {
            false
        } catch (_: SecurityException) {
            false
        }
    }

    @SuppressLint("MissingPermission")
    private fun getSuggestionApprovalStatus(wifiManager: WifiManager): Int? {
        val approvalStatus = AtomicInteger(WifiManager.STATUS_SUGGESTION_APPROVAL_UNKNOWN)
        val latch = CountDownLatch(1)
        val listener = WifiManager.SuggestionUserApprovalStatusListener { status ->
            approvalStatus.set(status)
            latch.countDown()
        }

        return try {
            wifiManager.addSuggestionUserApprovalStatusListener(DirectExecutor, listener)
            latch.await(APPROVAL_STATUS_TIMEOUT_MS, TimeUnit.MILLISECONDS)
            approvalStatus.get()
        } catch (_: RuntimeException) {
            null
        } finally {
            try {
                wifiManager.removeSuggestionUserApprovalStatusListener(listener)
            } catch (_: RuntimeException) {}
        }
    }

    private fun buildProvisioningResult(
        status: String,
        wifiEnabled: Boolean? = null,
        usedHiddenCaPath: Boolean = false,
        networkSuggestionStatus: Int? = null,
        approvalStatus: Int? = null,
        message: String? = null,
    ): Map<String, Any?> {
        return mapOf(
            "status" to status,
            "sdkInt" to Build.VERSION.SDK_INT,
            "wifiEnabled" to wifiEnabled,
            "usedHiddenCaPath" to usedHiddenCaPath,
            "networkSuggestionStatus" to networkSuggestionStatus,
            "approvalStatus" to approvalStatus,
            "message" to message,
        )
    }

    private fun canResolve(intent: Intent?): Boolean {
        intent ?: return false
        return intent.resolveActivity(packageManager) != null
    }

    private fun openIntent(intent: Intent?): Boolean {
        intent ?: return false
        if (!canResolve(intent)) return false

        return try {
            startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    private object DirectExecutor : Executor {
        override fun execute(command: Runnable) {
            command.run()
        }
    }
}
