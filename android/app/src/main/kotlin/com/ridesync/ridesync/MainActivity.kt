package com.ridesync.ridesync

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ridesync.ridesync/config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getApiKey" -> {
                    try {
                        val ai = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                        val bundle = ai.metaData
                        val apiKey = bundle.getString("com.google.android.geo.API_KEY")
                        result.success(apiKey)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "API Key not available.", null)
                    }
                }
                "getSignature" -> {
                    try {
                        val packageInfo = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                        } else {
                            @Suppress("DEPRECATION")
                            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
                        }

                        val signatures = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                            packageInfo.signingInfo?.signingCertificateHistory
                        } else {
                            @Suppress("DEPRECATION")
                            packageInfo.signatures
                        }

                        if (signatures != null && signatures.isNotEmpty()) {
                            val md = java.security.MessageDigest.getInstance("SHA-1")
                            val signatureBytes = signatures[0].toByteArray()
                            val digest = md.digest(signatureBytes)
                            val hexString = digest.joinToString("") { "%02X".format(it) }
                            result.success(hexString)
                        } else {
                            result.error("UNAVAILABLE", "No signatures found.", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
