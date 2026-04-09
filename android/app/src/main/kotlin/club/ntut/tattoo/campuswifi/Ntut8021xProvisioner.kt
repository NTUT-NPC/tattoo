package club.ntut.tattoo.campuswifi

import android.annotation.SuppressLint
import android.app.Activity
import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.net.wifi.WifiEnterpriseConfig
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSuggestion
import android.os.Build
import android.os.Process
import android.provider.Settings
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
        private const val CHANGE_WIFI_STATE_APP_OP = "android:change_wifi_state"
    }

    private val wifiManager: WifiManager?
        get() = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager

    fun canProvision(): Boolean {
        return wifiManager != null && supportsSystemCertificateValidation()
    }

    fun canCompatProvision(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
            wifiManager != null &&
            supportsSystemCertificateValidation()
    }

    @SuppressLint("MissingPermission")
    fun provisionNtut8021x(
        identity: String,
        password: String,
        previousIdentity: String? = null,
        previousPassword: String? = null,
    ): Map<String, Any?> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return buildProvisioningResult(status = "unsupportedPlatform")
        }

        val wifiManager = wifiManager
            ?: return buildProvisioningResult(status = "unsupportedPlatform")
        val wifiEnabled = wifiManager.isWifiEnabled

        val suggestion = try {
            buildSuggestion(identity, password)
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

        val previousSuggestion = try {
            when {
                previousIdentity.isNullOrBlank() || previousPassword.isNullOrBlank() -> null
                previousIdentity == identity && previousPassword == password -> null
                else -> buildSuggestion(previousIdentity, previousPassword)
            }
        } catch (_: IllegalArgumentException) {
            null
        } catch (_: RuntimeException) {
            null
        }

        val removalStatus = removeExistingSuggestions(
            wifiManager = wifiManager,
            suggestion = suggestion,
            previousSuggestion = previousSuggestion,
        )
        if (removalStatus != null) {
            return buildProvisioningResult(
                status = "failed",
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = true,
                networkSuggestionStatus = removalStatus,
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
        val suggestionPermissionState = getSuggestionPermissionState()
        return when (suggestionStatus) {
            WifiManager.STATUS_NETWORK_SUGGESTIONS_SUCCESS,
            WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_ADD_DUPLICATE,
            -> buildProvisioningResult(
                status = if (wifiEnabled) "success" else "successPendingWifi",
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = true,
                networkSuggestionStatus = suggestionStatus,
                approvalStatus = approvalStatus,
                suggestionPermissionState = suggestionPermissionState,
            )

            WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_APP_DISALLOWED -> buildProvisioningResult(
                status = when (approvalStatus) {
                    WifiManager.STATUS_SUGGESTION_APPROVAL_REJECTED_BY_USER -> "approvalRejected"
                    else -> when (suggestionPermissionState) {
                        "disallowed" -> "approvalRejected"
                        else -> "approvalPending"
                    }
                },
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = true,
                networkSuggestionStatus = suggestionStatus,
                approvalStatus = approvalStatus,
                suggestionPermissionState = suggestionPermissionState,
            )

            WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_ADD_NOT_ALLOWED -> buildProvisioningResult(
                status = when (suggestionPermissionState) {
                    "disallowed" -> "approvalRejected"
                    else -> "approvalPending"
                },
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = true,
                networkSuggestionStatus = suggestionStatus,
                approvalStatus = approvalStatus,
                suggestionPermissionState = suggestionPermissionState,
            )

            WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_RESTRICTED_BY_ADMIN -> buildProvisioningResult(
                status = "failed",
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = true,
                networkSuggestionStatus = suggestionStatus,
                approvalStatus = approvalStatus,
                suggestionPermissionState = suggestionPermissionState,
                message = "restricted_by_admin",
            )

            WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_ADD_INVALID -> buildProvisioningResult(
                status = "validationUnavailable",
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = true,
                networkSuggestionStatus = suggestionStatus,
                approvalStatus = approvalStatus,
                suggestionPermissionState = suggestionPermissionState,
            )

            else -> buildProvisioningResult(
                status = "failed",
                wifiEnabled = wifiEnabled,
                usedHiddenCaPath = true,
                networkSuggestionStatus = suggestionStatus,
                approvalStatus = approvalStatus,
                suggestionPermissionState = suggestionPermissionState,
            )
        }
    }

    fun buildAddNetworkIntent(
        identity: String,
        password: String,
    ): Intent? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            return null
        }

        val suggestion = buildSuggestion(identity, password)
        return Intent(Settings.ACTION_WIFI_ADD_NETWORKS).apply {
            putParcelableArrayListExtra(
                Settings.EXTRA_WIFI_NETWORK_LIST,
                arrayListOf(suggestion),
            )
        }
    }

    fun parseAddNetworkResult(
        resultCode: Int,
        data: Intent?,
    ): Map<String, Any?> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            return buildAddNetworkResult(status = "unsupportedPlatform")
        }

        val resultCodes = data
            ?.getIntegerArrayListExtra(Settings.EXTRA_WIFI_NETWORK_RESULT_LIST)
            ?.toList()
            .orEmpty()
        val primaryResultCode = resultCodes.firstOrNull()
        val wifiEnabled = wifiManager?.isWifiEnabled

        if (resultCode != Activity.RESULT_OK) {
            return buildAddNetworkResult(
                status = "compatCancelled",
                activityResultCode = resultCode,
                wifiEnabled = wifiEnabled,
                addNetworkResultCodes = resultCodes,
                compatResultCode = resultCode,
                compatNetworkResultCode = primaryResultCode,
            )
        }

        val hasFailure = resultCodes.any { it == Settings.ADD_WIFI_RESULT_ADD_OR_UPDATE_FAILED }
        val hasSuccess = resultCodes.any { it == Settings.ADD_WIFI_RESULT_SUCCESS }
        val onlyAlreadyExists = resultCodes.isNotEmpty() &&
            resultCodes.all { it == Settings.ADD_WIFI_RESULT_ALREADY_EXISTS }

        return when {
            hasFailure -> buildAddNetworkResult(
                status = "compatFailed",
                activityResultCode = resultCode,
                wifiEnabled = wifiEnabled,
                addNetworkResultCodes = resultCodes,
                compatResultCode = resultCode,
                compatNetworkResultCode = primaryResultCode,
            )
            onlyAlreadyExists -> buildAddNetworkResult(
                status = "compatAlreadyExists",
                activityResultCode = resultCode,
                wifiEnabled = wifiEnabled,
                addNetworkResultCodes = resultCodes,
                compatResultCode = resultCode,
                compatNetworkResultCode = primaryResultCode,
            )
            hasSuccess || resultCodes.isEmpty() -> buildAddNetworkResult(
                status = "compatSuccess",
                activityResultCode = resultCode,
                wifiEnabled = wifiEnabled,
                addNetworkResultCodes = resultCodes,
                compatResultCode = resultCode,
                compatNetworkResultCode = primaryResultCode,
            )
            else -> buildAddNetworkResult(
                status = "compatFailed",
                activityResultCode = resultCode,
                wifiEnabled = wifiEnabled,
                addNetworkResultCodes = resultCodes,
                compatResultCode = resultCode,
                compatNetworkResultCode = primaryResultCode,
            )
        }
    }

    private fun buildSuggestion(
        identity: String,
        password: String,
    ): WifiNetworkSuggestion {
        val enterpriseConfig = buildEnterpriseConfig(identity, password)
        if (!enableSystemCertificateValidation(enterpriseConfig)) {
            throw IllegalArgumentException("system_certificate_validation_unavailable")
        }

        return WifiNetworkSuggestion.Builder()
            .setSsid(NTUT_8021X_SSID)
            .setWpa2EnterpriseConfig(enterpriseConfig)
            .setCredentialSharedWithUser(true)
            .setIsInitialAutojoinEnabled(true)
            .build()
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

    private fun supportsSystemCertificateValidation(): Boolean {
        return try {
            WifiEnterpriseConfig::class.java.getMethod(
                "setCaPath",
                String::class.java,
            )
            true
        } catch (_: NoSuchMethodException) {
            false
        } catch (_: SecurityException) {
            false
        }
    }

    @SuppressLint("MissingPermission")
    private fun removeExistingSuggestions(
        wifiManager: WifiManager,
        suggestion: WifiNetworkSuggestion,
        previousSuggestion: WifiNetworkSuggestion?,
    ): Int? {
        val suggestionsToRemove = buildList {
            add(suggestion)
            if (previousSuggestion != null) add(previousSuggestion)
        }

        val removeStatus = try {
            wifiManager.removeNetworkSuggestions(suggestionsToRemove)
        } catch (_: SecurityException) {
            return null
        } catch (_: RuntimeException) {
            return WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_INTERNAL
        }

        return when (removeStatus) {
            WifiManager.STATUS_NETWORK_SUGGESTIONS_SUCCESS,
            WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_REMOVE_INVALID,
            -> null
            else -> removeStatus
        }
    }

    @SuppressLint("MissingPermission")
    private fun getSuggestionApprovalStatus(wifiManager: WifiManager): Int? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return null
        }

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

    fun getSuggestionPermissionState(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return "unknown"
        }

        val appOpsManager = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
            ?: return "unknown"
        val op = CHANGE_WIFI_STATE_APP_OP
        val uid = Process.myUid()
        val packageName = context.packageName
        val mode = try {
            appOpsManager.unsafeCheckOpNoThrow(op, uid, packageName)
        } catch (_: SecurityException) {
            appOpsManager.checkOpNoThrow(op, uid, packageName)
        }
        return when (mode) {
            AppOpsManager.MODE_ALLOWED,
            AppOpsManager.MODE_DEFAULT,
            AppOpsManager.MODE_FOREGROUND,
            -> "allowed"
            AppOpsManager.MODE_IGNORED,
            AppOpsManager.MODE_ERRORED,
            -> "disallowed"
            else -> "unknown"
        }
    }

    fun buildAddNetworkResult(
        status: String,
        activityResultCode: Int? = null,
        wifiEnabled: Boolean? = null,
        addNetworkResultCodes: List<Int> = emptyList(),
        compatResultCode: Int? = null,
        compatNetworkResultCode: Int? = null,
        message: String? = null,
    ): Map<String, Any?> {
        return mapOf(
            "status" to status,
            "sdkInt" to Build.VERSION.SDK_INT,
            "activityResultCode" to activityResultCode,
            "wifiEnabled" to wifiEnabled,
            "usedHiddenCaPath" to true,
            "addNetworkResultCodes" to addNetworkResultCodes,
            "compatResultCode" to compatResultCode,
            "compatNetworkResultCode" to compatNetworkResultCode,
            "message" to message,
        )
    }

    private fun buildProvisioningResult(
        status: String,
        wifiEnabled: Boolean? = null,
        usedHiddenCaPath: Boolean = false,
        networkSuggestionStatus: Int? = null,
        approvalStatus: Int? = null,
        suggestionPermissionState: String? = null,
        message: String? = null,
    ): Map<String, Any?> {
        return mapOf(
            "status" to status,
            "sdkInt" to Build.VERSION.SDK_INT,
            "wifiEnabled" to wifiEnabled,
            "usedHiddenCaPath" to usedHiddenCaPath,
            "networkSuggestionStatus" to networkSuggestionStatus,
            "approvalStatus" to approvalStatus,
            "suggestionPermissionState" to suggestionPermissionState,
            "message" to message,
        )
    }

    private object DirectExecutor : Executor {
        override fun execute(command: Runnable) {
            command.run()
        }
    }
}
