package club.ntut.tattoo

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.io.ByteArrayOutputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlinx.coroutines.*

/// Flutter plugin that performs HTTP requests using Android's [HttpURLConnection].
///
/// [HttpURLConnection] uses the system's Conscrypt TLS provider, whose TLS
/// fingerprint is shared by virtually every Android app and passes through
/// network firewalls that block non-standard TLS stacks (BoringSSL from
/// dart:io / Cronet, OpenSSL from curl, etc.).
class NativeHttpPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "club.ntut.tattoo/native_http")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "fetch" -> {
                val url = call.argument<String>("url")!!
                val method = call.argument<String>("method")!!
                val headers = call.argument<Map<String, List<Any>>>("headers") ?: emptyMap()
                val body = call.argument<ByteArray>("body")
                val followRedirects = call.argument<Boolean>("followRedirects") ?: false
                val connectTimeout = call.argument<Int>("connectTimeout")
                val readTimeout = call.argument<Int>("readTimeout")

                scope.launch {
                    try {
                        val response = performRequest(url, method, headers, body, followRedirects, connectTimeout, readTimeout)
                        withContext(Dispatchers.Main) {
                            result.success(response)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("HTTP_ERROR", e.message, null)
                        }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun performRequest(
        urlString: String,
        method: String,
        headers: Map<String, List<Any>>,
        body: ByteArray?,
        followRedirects: Boolean,
        connectTimeout: Int?,
        readTimeout: Int?
    ): Map<String, Any?> {
        val url = URL(urlString)
        val connection = url.openConnection() as HttpURLConnection

        try {
            connection.requestMethod = method
            connection.instanceFollowRedirects = followRedirects
            connection.connectTimeout = connectTimeout ?: 30_000
            connection.readTimeout = readTimeout ?: 30_000

            // Pass through all headers from Dio (including cookies set by CookieManager)
            for ((key, values) in headers) {
                for (value in values) {
                    connection.addRequestProperty(key, value.toString())
                }
            }

            // Write request body
            if (body != null && body.isNotEmpty()) {
                connection.doOutput = true
                connection.outputStream.use { it.write(body) }
            }

            val statusCode = connection.responseCode
            val statusMessage = connection.responseMessage

            // Collect response headers, preserving multiple values per key.
            // HttpURLConnection exposes headers via index; index 0 has a null
            // key (the status line), so we skip null keys.
            val responseHeaders = mutableMapOf<String, MutableList<String>>()
            var i = 0
            while (true) {
                val value = connection.getHeaderField(i) ?: break
                val key = connection.getHeaderFieldKey(i)
                if (key != null) {
                    responseHeaders
                        .getOrPut(key.lowercase()) { mutableListOf() }
                        .add(value)
                }
                i++
            }

            // Read response body from the appropriate stream
            val inputStream = try {
                connection.inputStream
            } catch (_: Exception) {
                connection.errorStream
            }

            val responseBody = if (inputStream != null) {
                val buffer = ByteArrayOutputStream()
                inputStream.use { input ->
                    val data = ByteArray(8192)
                    var bytesRead: Int
                    while (input.read(data).also { bytesRead = it } != -1) {
                        buffer.write(data, 0, bytesRead)
                    }
                }
                buffer.toByteArray()
            } else {
                ByteArray(0)
            }

            return mapOf(
                "statusCode" to statusCode,
                "statusMessage" to statusMessage,
                "headers" to responseHeaders,
                "body" to responseBody,
                "isRedirect" to (statusCode in 300..399)
            )
        } finally {
            connection.disconnect()
        }
    }
}
