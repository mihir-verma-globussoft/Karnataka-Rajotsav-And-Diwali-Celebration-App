package com.globus.rajotsav_and_diwali_celebration_app.ar

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter <-> native AR contract (Dart side: lib/features/ar/data).
 * Channel: festival_app/ar. Owner: AR developer.
 * ARCore is not integrated yet, so availability is reported as "unavailable".
 */
class ArChannel(messenger: BinaryMessenger) {
    init {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAvailability" -> result.success("unavailable")
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        const val CHANNEL = "festival_app/ar"
    }
}
