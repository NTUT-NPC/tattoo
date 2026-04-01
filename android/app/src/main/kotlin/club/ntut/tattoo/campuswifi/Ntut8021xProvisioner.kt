package club.ntut.tattoo.campuswifi

import android.annotation.SuppressLint
import android.content.Context
import android.net.wifi.WifiEnterpriseConfig
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSuggestion
import android.os.Build
import java.lang.reflect.InvocationTargetException
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

class Ntut8021xProvisioner(
    private val context: Context,
) {
    companion object {
        private const val NTUT_8021X_SSID = "NTUT-802.1X"
        private const val NTUT_DOMAIN_SUFFIX = "ntut.edu.tw"
        private const val SYSTEM_CA_CERT_PATH = "/system/etc/security/cacerts"
        private const val APPROVAL_STATUS_TIMEOUT_MS = 500L
    }

    private val wifiManager: WifiManager?
        get() = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager

    fun canProvision(): Boolean {
        return wifiManager != null
    }

    @SuppressLint("MissingPermission")
    fun provisionNtut8021x(identity: String, password: String): Map<String, Any?> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return buildProvisioningResult(status = "unsupportedPlatform")
        }

        val wifiManager = wifiManager
            ?: return buildProvisioningResult(status = "unsupportedPlatform")
        val wifiEnabled = wifiManager.isWifiEnabled

        val enterpriseConfig = buildEnterpriseConfig(identity, password)

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

    private fun buildEnterpriseConfig(
        identity: String,
        password: String,
    ): WifiEnterpriseConfig {
        return WifiEnterpriseConfig().apply {
            eapMethod = WifiEnterpriseConfig.Eap.PEAP
            phase2Method = WifiEnterpriseConfig.Phase2.GTC
            setIdentity(identity)
            setPassword(password)
            setDomainSuffixMatch(NTUT_DOMAIN_SUFFIX)
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

    private object DirectExecutor : Executor {
        override fun execute(command: Runnable) {
            command.run()
        }
    }
}
