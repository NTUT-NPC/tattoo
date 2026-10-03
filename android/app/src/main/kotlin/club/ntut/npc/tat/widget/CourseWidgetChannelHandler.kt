package club.ntut.npc.tat.widget

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class CourseWidgetChannelHandler(context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        private const val CHANNEL_NAME = "club.ntut.tattoo/course_widget"
        const val OPEN_COURSE_TABLE_ACTION = "club.ntut.npc.tat.action.OPEN_COURSE_TABLE"
        const val WIDGET_ROUTE_EXTRA = "widget_route"
        const val COURSE_TABLE_ROUTE = "/course-table"
    }

    private val storage = CourseWidgetStorage(context)
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var channel: MethodChannel? = null
    private var pendingRoute: String? = null
    private var dartReady = false

    fun register(binaryMessenger: BinaryMessenger) {
        dartReady = false
        channel = MethodChannel(binaryMessenger, CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
    }

    fun handleIntent(intent: Intent?) {
        if (
            intent?.action != OPEN_COURSE_TABLE_ACTION ||
            intent.getStringExtra(WIDGET_ROUTE_EXTRA) != COURSE_TABLE_ROUTE
        ) {
            return
        }
        pendingRoute = COURSE_TABLE_ROUTE
        deliverPendingRoute()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "readFingerprint" -> runStorage(result) { storage.readFingerprint() }
            "commitBitmaps" -> commitBitmaps(call, result)
            "clear" -> runStorage(result) { storage.clear() }
            "takePendingRoute" -> {
                dartReady = true
                val route = pendingRoute
                pendingRoute = null
                result.success(route)
            }
            else -> result.notImplemented()
        }
    }

    private fun commitBitmaps(call: MethodCall, result: MethodChannel.Result) {
        val lightPng = call.argument<ByteArray>("lightPng")
        val darkPng = call.argument<ByteArray>("darkPng")
        val fingerprint = call.argument<String>("fingerprint")
        if (
            lightPng == null ||
            lightPng.isEmpty() ||
            darkPng == null ||
            darkPng.isEmpty() ||
            fingerprint.isNullOrEmpty()
        ) {
            result.error(
                "invalid_arguments",
                "lightPng, darkPng, and fingerprint are required",
                null,
            )
            return
        }
        runStorage(result) {
            storage.commitBitmaps(lightPng, darkPng, fingerprint)
        }
    }

    private fun runStorage(result: MethodChannel.Result, operation: () -> Any?) {
        executor.execute {
            try {
                val value = operation()
                mainHandler.post { result.success(value.takeUnless { it === Unit }) }
            } catch (error: Exception) {
                mainHandler.post {
                    result.error("storage_error", error.message, null)
                }
            }
        }
    }

    private fun deliverPendingRoute() {
        if (!dartReady) return
        val route = pendingRoute ?: return
        channel?.invokeMethod(
            "openRoute",
            mapOf("route" to route),
            object : MethodChannel.Result {
                override fun success(result: Any?) {
                    if (pendingRoute == route) pendingRoute = null
                }

                override fun error(code: String, message: String?, details: Any?) {}

                override fun notImplemented() {}
            },
        )
    }
}
