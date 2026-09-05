package club.ntut.npc.tat

import android.app.Activity
import android.app.LocaleManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.LocaleList
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SystemSettingsChannelHandler(
    private val activity: Activity,
) : MethodChannel.MethodCallHandler {
    fun register(binaryMessenger: BinaryMessenger) {
        MethodChannel(binaryMessenger, CHANNEL_NAME).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getAppLanguage" -> result.success(getAppLanguage())
            "setAppLanguage" -> {
                val languageTag = call.argument<String>("languageTag")
                setAppLanguage(languageTag)
                result.success(getAppLanguage())
            }
            "openLanguageSettings" -> openLanguageSettings(result)
            else -> result.notImplemented()
        }
    }

    private fun getAppLanguage(): Map<String, Any?> {
        val isSystemManaged = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
        val languageTag = if (isSystemManaged) {
            val localeManager = activity.getSystemService(LocaleManager::class.java)
            localeManager.applicationLocales.takeUnless(LocaleList::isEmpty)?.get(0)?.toLanguageTag()
        } else {
            preferences.getString(LEGACY_LANGUAGE_KEY, null)
        }
        return mapOf(
            "languageTag" to languageTag,
            "isSystemManaged" to isSystemManaged,
        )
    }

    private fun setAppLanguage(languageTag: String?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val localeManager = activity.getSystemService(LocaleManager::class.java)
            localeManager.applicationLocales = if (languageTag == null) {
                LocaleList.getEmptyLocaleList()
            } else {
                LocaleList.forLanguageTags(languageTag)
            }
            return
        }

        preferences.edit().apply {
            if (languageTag == null) {
                remove(LEGACY_LANGUAGE_KEY)
            } else {
                putString(LEGACY_LANGUAGE_KEY, languageTag)
            }
        }.apply()
    }

    private fun openLanguageSettings(result: MethodChannel.Result) {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Intent(Settings.ACTION_APP_LOCALE_SETTINGS).apply {
                data = Uri.parse("package:${activity.packageName}")
            }
        } else {
            Intent(Settings.ACTION_LOCALE_SETTINGS)
        }

        try {
            activity.startActivity(intent)
            result.success(null)
        } catch (error: Exception) {
            result.error(
                "settings_unavailable",
                "Unable to open language settings.",
                error.message,
            )
        }
    }

    private val preferences by lazy {
        activity.getSharedPreferences(PREFERENCES_NAME, Activity.MODE_PRIVATE)
    }

    private companion object {
        const val CHANNEL_NAME = "club.ntut.tattoo/system_settings"
        const val PREFERENCES_NAME = "tattoo_system_settings"
        const val LEGACY_LANGUAGE_KEY = "app_language"
    }
}
