package club.ntut.tattoo

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.io.ByteArrayOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.Collections
import java.util.HashSet
import java.util.concurrent.ConcurrentHashMap
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
    private val activeRequests = ConcurrentHashMap<String, HttpURLConnection>()
    private val cancelledRequests = Collections.synchronizedSet(HashSet<String>())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "club.ntut.tattoo/native_http")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
        activeRequests.forEach { (_, connection) ->
            try { connection.disconnect() } catch (_: Exception) {}
        }
        activeRequests.clear()
        cancelledRequests.clear()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "fetch" -> {
                val requestId = try { call.argument<String>("requestId") } catch (e: Exception) { null }
                val url = try { call.argument<String>("url") } catch (e: Exception) {
                    result.error("BAD_ARGUMENT", "Malformed 'url' argument: ${e.message}", null)
                    return
                }
                val method = try { call.argument<String>("method") } catch (e: Exception) {
                    result.error("BAD_ARGUMENT", "Malformed 'method' argument: ${e.message}", null)
                    return
                }

                if (url == null) {
                    result.error("BAD_ARGUMENT", "Missing or null 'url' argument", null)
                    return
                }
                if (method == null) {
                    result.error("BAD_ARGUMENT", "Missing or null 'method' argument", null)
                    return
                }

                val headers = try { call.argument<Map<String, List<Any>>>("headers") ?: emptyMap() } catch (e: Exception) {
                    result.error("BAD_ARGUMENT", "Malformed 'headers' argument: ${e.message}", null)
                    return
                }
                val body = try { call.argument<ByteArray>("body") } catch (e: Exception) {
                    result.error("BAD_ARGUMENT", "Malformed 'body' argument: ${e.message}", null)
                    return
                }
                val followRedirects = try { call.argument<Boolean>("followRedirects") ?: false } catch (e: Exception) {
                    result.error("BAD_ARGUMENT", "Malformed 'followRedirects' argument: ${e.message}", null)
                    return
                }
                val connectTimeout = try { call.argument<Int>("connectTimeout") } catch (e: Exception) {
                    result.error("BAD_ARGUMENT", "Malformed 'connectTimeout' argument: ${e.message}", null)
                    return
                }
                val readTimeout = try { call.argument<Int>("readTimeout") } catch (e: Exception) {
                    result.error("BAD_ARGUMENT", "Malformed 'readTimeout' argument: ${e.message}", null)
                    return
                }

                scope.launch {
                    try {
                        val response = performRequest(requestId, url, method, headers, body, followRedirects, connectTimeout, readTimeout)
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
            "cancel" -> {
                val requestId = try { call.argument<String>("requestId") } catch (e: Exception) { null }
                if (requestId != null) {
                    if (cancelledRequests.size > 500) {
                        cancelledRequests.clear()
                    }
                    cancelledRequests.add(requestId)
                    val connection = activeRequests.remove(requestId)
                    connection?.disconnect()
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun performRequest(
        requestId: String?,
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

        if (requestId != null) {
            if (cancelledRequests.contains(requestId)) {
                cancelledRequests.remove(requestId)
                throw java.io.IOException("Request cancelled")
            }
            activeRequests[requestId] = connection
            if (cancelledRequests.contains(requestId)) {
                activeRequests.remove(requestId)
                cancelledRequests.remove(requestId)
                connection.disconnect()
                throw java.io.IOException("Request cancelled")
            }
        }

        try {
            if (body != null && body.isNotEmpty()) {
                connection.doOutput = true
            }

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
            if (requestId != null) {
                activeRequests.remove(requestId)
                cancelledRequests.remove(requestId)
            }
            connection.disconnect()
        }
    }
}
