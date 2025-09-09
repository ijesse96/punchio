package com.punchio.punchio

import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.nio.ByteBuffer

class AudioMonitoringPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    private var isMonitoring = false
    private var monitoringJob: Job? = null
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "audio_monitoring")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startMonitoring" -> {
                startMonitoring(result)
            }
            "stopMonitoring" -> {
                stopMonitoring(result)
            }
            "isMonitoring" -> {
                result.success(isMonitoring)
            }
            "setMonitoringVolume" -> {
                val volume = call.argument<Double>("volume") ?: 0.5
                setMonitoringVolume(volume, result)
            }
            "getAudioLevel" -> {
                getAudioLevel(result)
            }
            "getLatency" -> {
                getLatency(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    fun startMonitoring(result: Result) {
        try {
            if (isMonitoring) {
                result.success(true)
                return
            }

            // Try different configurations in order of preference
            val configurations = listOf(
                AudioConfig(48000, "ultra-low", 4), // Ultra-low latency
                AudioConfig(48000, "low", 2),       // Low latency
                AudioConfig(44100, "standard", 1),  // Standard
                AudioConfig(44100, "conservative", 1) // Conservative fallback
            )

            var success = false
            for (config in configurations) {
                try {
                    if (tryAudioConfiguration(config)) {
                        Log.d("AudioMonitoring", "Monitoring started with ${config.name} latency (${config.sampleRate}Hz, buffer: ${config.bufferSize})")
                        success = true
                        break
                    }
                } catch (e: Exception) {
                    Log.w("AudioMonitoring", "Failed ${config.name} config: ${e.message}")
                    cleanup()
                }
            }

            if (success) {
                result.success(true)
            } else {
                result.error("MONITORING_ERROR", "Failed to start monitoring: No valid configuration found", null)
            }

        } catch (e: Exception) {
            Log.e("AudioMonitoring", "Failed to start monitoring", e)
            result.error("MONITORING_ERROR", "Failed to start monitoring: ${e.message}", null)
        }
    }

    private data class AudioConfig(
        val sampleRate: Int,
        val name: String,
        val bufferDivisor: Int
    ) {
        val bufferSize: Int
            get() {
                val minBufferSize = AudioRecord.getMinBufferSize(sampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
                return maxOf(minBufferSize / bufferDivisor, 1024) // Ensure minimum buffer size
            }
    }

    private fun tryAudioConfiguration(config: AudioConfig): Boolean {
        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val audioFormat = AudioFormat.ENCODING_PCM_16BIT
        val bufferSize = config.bufferSize

        // Create AudioRecord
        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            config.sampleRate,
            channelConfig,
            audioFormat,
            bufferSize
        )

        // Create AudioTrack
        val trackMinBufferSize = AudioTrack.getMinBufferSize(
            config.sampleRate,
            AudioFormat.CHANNEL_OUT_MONO,
            audioFormat
        )
        val trackBufferSize = maxOf(trackMinBufferSize / config.bufferDivisor, 1024)

        audioTrack = AudioTrack.Builder()
            .setAudioAttributes(
                android.media.AudioAttributes.Builder()
                    .setUsage(android.media.AudioAttributes.USAGE_VOICE_COMMUNICATION)
                    .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(audioFormat)
                    .setSampleRate(config.sampleRate)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build()
            )
            .setBufferSizeInBytes(trackBufferSize)
            .setTransferMode(AudioTrack.MODE_STREAM)
            .setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY)
            .build()

        audioRecord?.startRecording()
        audioTrack?.play()
        isMonitoring = true

        // Start monitoring loop
        monitoringJob = scope.launch(Dispatchers.IO) {
            val buffer = ByteArray(bufferSize)
            while (isMonitoring && isActive) {
                val bytesRead = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                if (bytesRead > 0) {
                    audioTrack?.write(buffer, 0, bytesRead, AudioTrack.WRITE_NON_BLOCKING)
                }
            }
        }

        return true
    }

    private fun cleanup() {
        try {
            monitoringJob?.cancel()
            audioRecord?.stop()
            audioRecord?.release()
            audioTrack?.stop()
            audioTrack?.release()
            audioRecord = null
            audioTrack = null
            isMonitoring = false
        } catch (e: Exception) {
            Log.e("AudioMonitoring", "Error during cleanup", e)
        }
    }

    fun stopMonitoring(result: Result) {
        try {
            cleanup()
            Log.d("AudioMonitoring", "Monitoring stopped")
            result.success(true)
        } catch (e: Exception) {
            Log.e("AudioMonitoring", "Failed to stop monitoring", e)
            result.error("MONITORING_ERROR", "Failed to stop monitoring: ${e.message}", null)
        }
    }

    private fun setMonitoringVolume(volume: Double, result: Result) {
        try {
            val clampedVolume = volume.coerceIn(0.0, 1.0)
            audioTrack?.setVolume(clampedVolume.toFloat())
            result.success(true)
        } catch (e: Exception) {
            Log.e("AudioMonitoring", "Failed to set volume", e)
            result.error("VOLUME_ERROR", "Failed to set volume: ${e.message}", null)
        }
    }

    private fun getAudioLevel(result: Result) {
        // For now, return a mock level. In a real implementation,
        // you'd calculate this from the audio buffer
        result.success(0.5)
    }

    private fun getLatency(result: Result) {
        // Calculate estimated latency based on buffer sizes
        val sampleRate = 48000
        val bufferSize = audioRecord?.bufferSizeInFrames ?: 0
        val trackBufferSize = audioTrack?.bufferSizeInFrames ?: 0
        
        // Total latency = input buffer + output buffer + processing overhead
        val inputLatency = (bufferSize * 1000.0) / sampleRate
        val outputLatency = (trackBufferSize * 1000.0) / sampleRate
        val totalLatency = inputLatency + outputLatency + 2.0 // 2ms processing overhead
        
        result.success(totalLatency)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        // Clean up monitoring resources
        isMonitoring = false
        monitoringJob?.cancel()
        audioRecord?.release()
        audioTrack?.release()
        scope.cancel()
    }
}
