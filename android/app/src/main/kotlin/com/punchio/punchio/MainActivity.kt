package com.punchio.punchio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.punchio.punchio/audio_monitoring"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startMonitoring" -> {
                    AudioMonitoringPlugin().startMonitoring(result)
                }
                "stopMonitoring" -> {
                    AudioMonitoringPlugin().stopMonitoring(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
