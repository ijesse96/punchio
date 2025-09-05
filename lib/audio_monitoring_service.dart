import 'package:flutter/services.dart';

class AudioMonitoringService {
  static const MethodChannel _channel = MethodChannel('audio_monitoring');

  /// Start real-time audio monitoring
  static Future<bool> startMonitoring() async {
    try {
      final result = await _channel.invokeMethod('startMonitoring');
      return result == true;
    } catch (e) {
              // print('Failed to start monitoring: $e');
      return false;
    }
  }

  /// Stop real-time audio monitoring
  static Future<bool> stopMonitoring() async {
    try {
      final result = await _channel.invokeMethod('stopMonitoring');
      return result == true;
    } catch (e) {
              // print('Failed to stop monitoring: $e');
      return false;
    }
  }

  /// Check if monitoring is currently active
  static Future<bool> isMonitoring() async {
    try {
      final result = await _channel.invokeMethod('isMonitoring');
      return result == true;
    } catch (e) {
      // print('Failed to check monitoring status: $e');
      return false;
    }
  }

  /// Set monitoring volume (0.0 to 1.0)
  static Future<bool> setMonitoringVolume(double volume) async {
    try {
      final result = await _channel.invokeMethod('setMonitoringVolume', {'volume': volume});
      return result == true;
    } catch (e) {
              // print('Failed to set monitoring volume: $e');
      return false;
    }
  }

  /// Get current audio level (for UI feedback)
  static Future<double> getAudioLevel() async {
    try {
      final result = await _channel.invokeMethod('getAudioLevel');
      return (result as num).toDouble();
    } catch (e) {
              // print('Failed to get audio level: $e');
      return 0.0;
    }
  }

  /// Get estimated latency in milliseconds
  static Future<double> getLatency() async {
    try {
      final result = await _channel.invokeMethod('getLatency');
      return (result as num).toDouble();
    } catch (e) {
              // print('Failed to get latency: $e');
      return 0.0;
    }
  }
}
