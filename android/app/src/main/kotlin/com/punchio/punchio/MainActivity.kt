package com.punchio.punchio

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "audio_monitoring"
    private lateinit var audioPlugin: AudioMonitoringPlugin
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        audioPlugin = AudioMonitoringPlugin()
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startMonitoring" -> {
                    audioPlugin.startMonitoring(result)
                }
                "stopMonitoring" -> {
                    audioPlugin.stopMonitoring(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
