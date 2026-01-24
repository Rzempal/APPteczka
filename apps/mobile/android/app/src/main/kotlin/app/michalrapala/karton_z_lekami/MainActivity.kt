package app.michalrapala.karton_z_lekami

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.karton/file_intent"
    private var methodChannel: MethodChannel? = null
    private var pendingUri: String? = null
    private val pendingLogs = mutableListOf<String>()

    private fun log(message: String) {
        val fullMessage = "[MainActivity] $message"
        android.util.Log.d("MainActivity", message)
        
        if (methodChannel != null) {
            methodChannel?.invokeMethod("log", fullMessage)
        } else {
            pendingLogs.add(fullMessage)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        // Wyślij zaległe logi
        pendingLogs.forEach { methodChannel?.invokeMethod("log", it) }
        pendingLogs.clear()
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialFileUri" -> {
                    log("getInitialFileUri called, pendingUri=$pendingUri")
                    result.success(pendingUri)
                    pendingUri = null
                }
                "readContentUri" -> {
                    // Odczytaj plik z content:// URI używając ContentResolver
                    val uriString = call.argument<String>("uri")
                    if (uriString == null) {
                        result.error("INVALID_URI", "URI is null", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        val uri = Uri.parse(uriString)
                        val content = readContentUri(uri)
                        log("readContentUri: success, ${content.length} chars")
                        result.success(content)
                    } catch (e: Exception) {
                        log("readContentUri: error - ${e.message}")
                        result.error("READ_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        log("configureFlutterEngine completed")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        log("onCreate: action=${intent?.action}, data=${intent?.data}")
        
        val uri = extractUri(intent)
        if (uri != null) {
            log("onCreate: found URI=$uri")
            pendingUri = uri
        } else {
            log("onCreate: no URI found")
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        
        log("onNewIntent: action=${intent.action}")
        log("onNewIntent: data=${intent.data}")
        
        val uri = extractUri(intent)
        if (uri != null) {
            log("onNewIntent: sending URI to Flutter: $uri")
            methodChannel?.invokeMethod("onFileReceived", uri)
        } else {
            log("onNewIntent: no URI extracted")
        }
    }

    private fun extractUri(intent: Intent?): String? {
        if (intent == null) return null
        
        // 1. Bezpośrednie data URI
        intent.data?.let { 
            log("extractUri: found in intent.data")
            return it.toString() 
        }
        
        // 2. ClipData
        intent.clipData?.let { clipData ->
            if (clipData.itemCount > 0) {
                clipData.getItemAt(0)?.uri?.let { 
                    log("extractUri: found in clipData")
                    return it.toString() 
                }
            }
        }
        
        // 3. EXTRA_STREAM (dla ACTION_SEND)
        try {
            val streamUri = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_STREAM)
            }
            streamUri?.let { 
                log("extractUri: found in EXTRA_STREAM")
                return it.toString() 
            }
        } catch (e: Exception) {
            log("extractUri: EXTRA_STREAM error: ${e.message}")
        }
        
        return null
    }

    /// Odczytuje zawartość pliku z content:// URI
    private fun readContentUri(uri: Uri): String {
        val inputStream = contentResolver.openInputStream(uri)
            ?: throw Exception("Cannot open input stream for $uri")
        
        return inputStream.use { stream ->
            BufferedReader(InputStreamReader(stream)).use { reader ->
                reader.readText()
            }
        }
    }
}
