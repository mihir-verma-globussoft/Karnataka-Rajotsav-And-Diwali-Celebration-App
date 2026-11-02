package com.globus.rajotsav_and_diwali_celebration_app

import com.globus.rajotsav_and_diwali_celebration_app.ar.ArChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ArChannel(flutterEngine.dartExecutor.binaryMessenger)
    }
}
