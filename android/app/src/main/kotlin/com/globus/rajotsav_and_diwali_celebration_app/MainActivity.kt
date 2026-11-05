package com.globus.rajotsav_and_diwali_celebration_app

import com.globus.rajotsav_and_diwali_celebration_app.ar.ArChannel
import com.globus.rajotsav_and_diwali_celebration_app.ar.ArHuntViewFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var arChannel: ArChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        arChannel = ArChannel(this, messenger)
        flutterEngine.platformViewsController.registry
            .registerViewFactory(ArHuntViewFactory.VIEW_TYPE, ArHuntViewFactory(this, messenger))
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        arChannel?.onPermissionResult(requestCode, grantResults)
    }
}
