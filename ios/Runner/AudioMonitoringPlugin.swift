import Flutter
import UIKit
import AVFoundation

public class AudioMonitoringPlugin: NSObject, FlutterPlugin {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var outputNode: AVAudioOutputNode?
    private var isMonitoring = false
    private var monitoringVolume: Float = 0.5
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "audio_monitoring", binaryMessenger: registrar.messenger())
        let instance = AudioMonitoringPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startMonitoring":
            startMonitoring(result: result)
        case "stopMonitoring":
            stopMonitoring(result: result)
        case "isMonitoring":
            result(isMonitoring)
        case "setMonitoringVolume":
            if let args = call.arguments as? [String: Any],
               let volume = args["volume"] as? Double {
                setMonitoringVolume(volume: Float(volume), result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Volume must be a number", details: nil))
            }
        case "getAudioLevel":
            getAudioLevel(result: result)
        case "getLatency":
            getLatency(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startMonitoring(result: @escaping FlutterResult) {
        do {
            if isMonitoring {
                result(true)
                return
            }
            
            // Request microphone permission
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupAudioEngine(result: result)
                    } else {
                        result(FlutterError(code: "PERMISSION_DENIED", message: "Microphone permission denied", details: nil))
                    }
                }
            }
        } catch {
            result(FlutterError(code: "AUDIO_ERROR", message: "Failed to start monitoring: \(error.localizedDescription)", details: nil))
        }
    }
    
    private func setupAudioEngine(result: @escaping FlutterResult) {
        do {
            // Configure audio session for ultra-low latency
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, 
                                       mode: .voiceChat, // Voice chat mode for lowest latency
                                       options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            
            // Set preferred buffer duration for minimal latency
            try audioSession.setPreferredIOBufferDuration(0.005) // 5ms buffer
            try audioSession.setPreferredSampleRate(48000) // Higher sample rate
            
            try audioSession.setActive(true)
            
            // Create audio engine
            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else {
                result(FlutterError(code: "ENGINE_ERROR", message: "Failed to create audio engine", details: nil))
                return
            }
            
            inputNode = audioEngine.inputNode
            outputNode = audioEngine.outputNode
            
            guard let inputNode = inputNode, let outputNode = outputNode else {
                result(FlutterError(code: "NODE_ERROR", message: "Failed to get audio nodes", details: nil))
                return
            }
            
            // Get input format with optimized settings
            let inputFormat = inputNode.outputFormat(forBus: 0)
            
            // Create ultra-low latency format
            let lowLatencyFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)
            
            // Connect input directly to output for ultra-low latency passthrough
            audioEngine.connect(inputNode, to: outputNode, format: lowLatencyFormat)
            
            // Install tap for monitoring audio levels (optional)
            inputNode.installTap(onBus: 0, bufferSize: 256, format: lowLatencyFormat) { [weak self] buffer, _ in
                // This tap is just for monitoring - the actual audio passthrough happens via the connection above
                // You can add audio level monitoring or other processing here if needed
            }
            
            // Start the audio engine
            try audioEngine.start()
            isMonitoring = true
            
            print("Ultra-low latency audio monitoring started (buffer: 256 samples)")
            result(true)
            
        } catch {
            result(FlutterError(code: "SETUP_ERROR", message: "Failed to setup audio engine: \(error.localizedDescription)", details: nil))
        }
    }
    
    private func stopMonitoring(result: @escaping FlutterResult) {
        do {
            isMonitoring = false
            
            if let audioEngine = audioEngine {
                audioEngine.stop()
                inputNode?.removeTap(onBus: 0)
                // Disconnect the audio nodes
                audioEngine.disconnectNodeInput(inputNode!)
                audioEngine.disconnectNodeInput(outputNode!)
            }
            
            audioEngine = nil
            inputNode = nil
            outputNode = nil
            
            // Deactivate audio session
            try AVAudioSession.sharedInstance().setActive(false)
            
            print("Audio monitoring stopped")
            result(true)
            
        } catch {
            result(FlutterError(code: "STOP_ERROR", message: "Failed to stop monitoring: \(error.localizedDescription)", details: nil))
        }
    }
    
    private func setMonitoringVolume(volume: Float, result: @escaping FlutterResult) {
        monitoringVolume = max(0.0, min(1.0, volume))
        // In a real implementation, you'd apply this volume to the audio processing
        result(true)
    }
    
    private func getAudioLevel(result: @escaping FlutterResult) {
        // For now, return a mock level. In a real implementation,
        // you'd calculate this from the audio buffer
        result(0.5)
    }
    
    private func getLatency(result: @escaping FlutterResult) {
        // Calculate estimated latency based on buffer size and sample rate
        let sampleRate: Double = 48000
        let bufferSize: Double = 256 // Our ultra-low latency buffer size
        let ioBufferDuration: Double = 0.005 // 5ms IO buffer duration
        
        // Total latency = buffer processing + IO buffer duration + processing overhead
        let bufferLatency = (bufferSize * 1000.0) / sampleRate
        let ioLatency = ioBufferDuration * 1000.0
        let totalLatency = bufferLatency + ioLatency + 1.0 // 1ms processing overhead
        
        result(totalLatency)
    }
}
