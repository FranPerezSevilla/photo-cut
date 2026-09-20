package com.frainzzel.photocut

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val ENTITLEMENT_CHANNEL = "com.frainzzel.photocut/entitlement"
        private const val PREFS_NAME = "photo_cut_entitlement"
        private const val FREE_FINAL_PDF_CONSUMED = "free_final_pdf_consumed"
        private const val LIFETIME_UNLOCKED = "lifetime_unlocked"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ENTITLEMENT_CHANNEL,
        ).setMethodCallHandler { call, result ->
            val preferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            when (call.method) {
                "read" -> {
                    result.success(
                        mapOf(
                            "freeFinalPdfConsumed" to preferences.getBoolean(
                                FREE_FINAL_PDF_CONSUMED,
                                false,
                            ),
                            "lifetimeUnlocked" to preferences.getBoolean(
                                LIFETIME_UNLOCKED,
                                false,
                            ),
                        ),
                    )
                }

                "write" -> {
                    val arguments = call.arguments as? Map<*, *>
                    val freeFinalPdfConsumed =
                        arguments?.get("freeFinalPdfConsumed") as? Boolean
                    val lifetimeUnlocked =
                        arguments?.get("lifetimeUnlocked") as? Boolean

                    if (freeFinalPdfConsumed == null || lifetimeUnlocked == null) {
                        result.error(
                            "invalid_entitlement_state",
                            "Both entitlement booleans are required.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    preferences.edit()
                        .putBoolean(FREE_FINAL_PDF_CONSUMED, freeFinalPdfConsumed)
                        .putBoolean(LIFETIME_UNLOCKED, lifetimeUnlocked)
                        .apply()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }
}
