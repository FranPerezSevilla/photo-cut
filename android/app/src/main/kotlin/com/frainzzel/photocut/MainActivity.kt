package com.frainzzel.photocut

import android.content.Context
import android.content.SharedPreferences
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val ENTITLEMENT_CHANNEL = "com.frainzzel.photocut/entitlement"
        private const val ENTITLEMENT_PREFS_NAME = "photo_cut_entitlement"
        private const val FREE_USE_PREFS_NAME = "photo_cut_free_use"
        private const val FREE_FINAL_PDF_CONSUMED = "free_final_pdf_consumed"
        private const val LIFETIME_UNLOCKED = "lifetime_unlocked"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ENTITLEMENT_CHANNEL,
        ).setMethodCallHandler { call, result ->
            val entitlementPreferences =
                getSharedPreferences(ENTITLEMENT_PREFS_NAME, Context.MODE_PRIVATE)
            val freeUsePreferences =
                getSharedPreferences(FREE_USE_PREFS_NAME, Context.MODE_PRIVATE)

            when (call.method) {
                "read" -> {
                    val freeFinalPdfConsumed = readAndMigrateFreeUse(
                        entitlementPreferences,
                        freeUsePreferences,
                    )
                    result.success(
                        mapOf(
                            "freeFinalPdfConsumed" to freeFinalPdfConsumed,
                            "lifetimeUnlocked" to entitlementPreferences.getBoolean(
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

                    freeUsePreferences.edit()
                        .putBoolean(FREE_FINAL_PDF_CONSUMED, freeFinalPdfConsumed)
                        .apply()

                    entitlementPreferences.edit()
                        .remove(FREE_FINAL_PDF_CONSUMED)
                        .putBoolean(LIFETIME_UNLOCKED, lifetimeUnlocked)
                        .apply()

                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun readAndMigrateFreeUse(
        entitlementPreferences: SharedPreferences,
        freeUsePreferences: SharedPreferences,
    ): Boolean {
        if (freeUsePreferences.contains(FREE_FINAL_PDF_CONSUMED)) {
            return freeUsePreferences.getBoolean(FREE_FINAL_PDF_CONSUMED, false)
        }

        val legacyValue = entitlementPreferences.getBoolean(
            FREE_FINAL_PDF_CONSUMED,
            false,
        )
        if (entitlementPreferences.contains(FREE_FINAL_PDF_CONSUMED)) {
            freeUsePreferences.edit()
                .putBoolean(FREE_FINAL_PDF_CONSUMED, legacyValue)
                .apply()
            entitlementPreferences.edit()
                .remove(FREE_FINAL_PDF_CONSUMED)
                .apply()
        }
        return legacyValue
    }
}
