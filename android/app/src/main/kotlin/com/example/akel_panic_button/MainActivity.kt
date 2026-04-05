package com.akel.panic_button

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private val hardwarePlugin = HardwareButtonPlugin()

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        hardwarePlugin.onAttachedToEngine(flutterEngine)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        return hardwarePlugin.handleKeyEvent(event) || super.onKeyDown(keyCode, event)
    }
}