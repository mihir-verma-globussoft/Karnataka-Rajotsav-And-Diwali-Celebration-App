package com.globus.rajotsav_and_diwali_celebration_app.ar

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.google.ar.core.ArCoreApk
import com.google.ar.core.exceptions.UnavailableDeviceNotCompatibleException
import com.google.ar.core.exceptions.UnavailableUserDeclinedInstallationException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter <-> native AR contract (Dart side: lib/features/ar/data).
 * Channel: festival_app/ar. Answers are the names in ArAvailability.
 */
class ArChannel(
    private val activity: FlutterActivity,
    messenger: BinaryMessenger,
) : DefaultLifecycleObserver {
    private var pendingPrepare: MethodChannel.Result? = null
    private var installRequested = false

    init {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAvailability" -> checkAvailability(result)
                "prepare" -> prepare(result)
                "openSettings" -> {
                    openSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        activity.lifecycle.addObserver(this)
    }

    private fun checkAvailability(result: MethodChannel.Result) {
        ArCoreApk.getInstance().checkAvailabilityAsync(activity) { availability ->
            result.success(
                when (availability) {
                    ArCoreApk.Availability.SUPPORTED_INSTALLED -> "supported"
                    ArCoreApk.Availability.SUPPORTED_APK_TOO_OLD,
                    ArCoreApk.Availability.SUPPORTED_NOT_INSTALLED,
                    -> "servicesNeedInstall"
                    ArCoreApk.Availability.UNSUPPORTED_DEVICE_NOT_CAPABLE -> "unsupportedDevice"
                    else -> "unavailable"
                },
            )
        }
    }

    private fun prepare(result: MethodChannel.Result) {
        if (pendingPrepare != null) {
            result.error("busy", "Already preparing AR.", null)
            return
        }
        pendingPrepare = result
        if (activity.checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            install(userRequested = true)
        } else {
            activity.requestPermissions(arrayOf(Manifest.permission.CAMERA), REQUEST_CAMERA)
        }
    }

    /** Called from MainActivity. */
    fun onPermissionResult(requestCode: Int, grantResults: IntArray) {
        if (requestCode != REQUEST_CAMERA || pendingPrepare == null) return
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            install(userRequested = true)
        } else {
            finishPrepare("cameraPermissionDenied")
        }
    }

    private fun install(userRequested: Boolean) {
        try {
            when (ArCoreApk.getInstance().requestInstall(activity, userRequested)) {
                ArCoreApk.InstallStatus.INSTALLED -> finishPrepare("supported")
                // ARCore shows its own install screen; onResume carries on after it.
                ArCoreApk.InstallStatus.INSTALL_REQUESTED -> installRequested = true
            }
        } catch (_: UnavailableUserDeclinedInstallationException) {
            finishPrepare("servicesNeedInstall")
        } catch (_: UnavailableDeviceNotCompatibleException) {
            finishPrepare("unsupportedDevice")
        } catch (_: Exception) {
            finishPrepare("unavailable")
        }
    }

    override fun onResume(owner: LifecycleOwner) {
        if (installRequested) {
            installRequested = false
            install(userRequested = false)
        }
    }

    private fun finishPrepare(answer: String) {
        pendingPrepare?.success(answer)
        pendingPrepare = null
    }

    private fun openSettings() {
        activity.startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", activity.packageName, null)),
        )
    }

    companion object {
        const val CHANNEL = "festival_app/ar"
        private const val REQUEST_CAMERA = 7041
    }
}
