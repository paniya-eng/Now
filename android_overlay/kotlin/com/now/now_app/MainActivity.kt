package com.now.now_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "now/widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "refresh") {
                    NowWidgetProvider.refreshAll(applicationContext)
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }
    }
}
