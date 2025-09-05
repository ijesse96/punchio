import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'audio_monitoring_service.dart';

void main() {
  runApp(const PunchioApp());
}

class PunchioApp extends StatelessWidget {
  const PunchioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Punchio - Vocal Recorder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PunchioHomePage(),
    );
  }
}

class PunchioHomePage extends StatefulWidget {
  const PunchioHomePage({super.key});

  @override
  State<PunchioHomePage> createState() => _PunchioHomePageState();
}

class _PunchioHomePageState extends State<PunchioHomePage>
    with TickerProviderStateMixin {
  // Audio components
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  AudioPlayer? _metronomePlayer;
  
  // State variables
  int _bpm = 130;
  bool _isMetronomePlaying = false;
  bool _isRecording = false;
  bool _punchMode = false;
  bool _realtimeMonitoring = true; // New: Real-time audio monitoring
  Timer? _metronomeTimer;
  Timer? _recordingTimer;
  
  // Recording state
  final List<AudioSegment> _audioSegments = [];
  double _currentRecordingTime = 0.0;
  double _totalRecordingTime = 0.0;
  String? _currentRecordingPath;
  double _currentAudioLevel = 0.0; // Real-time audio level
  double _currentLatency = 0.0; // Current latency in milliseconds
  
  // Animation controllers
  late AnimationController _metronomeAnimationController;
  late Animation<double> _metronomeAnimation;
  
  // Mock waveform data
  final List<double> _mockWaveform = [];
  final ScrollController _timelineScrollController = ScrollController();
  
  // DAW Grid system
  double _zoomLevel = 1.0; // 1.0 = normal, 2.0 = 2x zoom, 0.5 = half zoom
  final double _minZoom = 0.25;
  final double _maxZoom = 4.0;
  int _currentBar = 1;
  int _totalBars = 32; // Default to 32 bars

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _initializeAnimations();
  }

  void _initializeAudio() async {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _metronomePlayer = AudioPlayer();
    
    await _recorder!.openRecorder();
    await _player!.openPlayer();
    
    // Request microphone and audio permissions
    await Permission.microphone.request();
    await Permission.notification.request();
    
    // Set up real-time monitoring
    _setupRealtimeMonitoring();
  }

  void _setupRealtimeMonitoring() {
    // Set up the recorder for real-time monitoring
    _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));
    
    // Listen to recording data for real-time waveform
    _recorder!.onProgress!.listen((RecordingDisposition disposition) {
      if (mounted) {
        setState(() {
          // Update waveform with real audio data
          final amplitude = disposition.decibels ?? 0.0;
          _currentAudioLevel = amplitude.abs();
          _mockWaveform.add(amplitude.abs() * 2); // Convert dB to visual amplitude
          
          // Keep only recent waveform data (last 10 seconds)
          if (_mockWaveform.length > 1000) {
            _mockWaveform.removeAt(0);
          }
        });
      }
    });
    
    // Audio session setup is now handled by native code
  }

  Future<void> _startAudioMonitoring() async {
    if (!_realtimeMonitoring) return;
    
    try {
      // Use native monitoring service
      final success = await AudioMonitoringService.startMonitoring();
      if (success) {
        print('🎤 Native audio monitoring started - you should now hear yourself!');
        
        // Get latency information
        _currentLatency = await AudioMonitoringService.getLatency();
        print('📊 Current latency: ${_currentLatency.toStringAsFixed(1)}ms');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎧 Ultra-Low Latency Monitoring ON (${_currentLatency.toStringAsFixed(1)}ms)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('❌ Failed to start native monitoring');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to start monitoring. Please check microphone permissions in Settings.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Failed to start native audio monitoring: $e');
    }
  }

  Future<void> _stopAudioMonitoring() async {
    try {
      // Use native monitoring service
      final success = await AudioMonitoringService.stopMonitoring();
      if (success) {
        print('🔇 Native audio monitoring stopped');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔇 Monitoring OFF'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('❌ Failed to stop native monitoring');
      }
    } catch (e) {
      print('Failed to stop native audio monitoring: $e');
    }
  }

  void _initializeAnimations() {
    _metronomeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _metronomeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _metronomeAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startMetronome() {
    if (_isMetronomePlaying) return;
    
    setState(() {
      _isMetronomePlaying = true;
    });
    
    final beatInterval = Duration(milliseconds: (60000 / _bpm).round());
    
    _metronomeTimer = Timer.periodic(beatInterval, (timer) {
      _metronomeAnimationController.forward().then((_) {
        _metronomeAnimationController.reverse();
      });
      
      // Play metronome tick sound (you can add actual audio file here)
      _playMetronomeTick();
    });
  }

  void _stopMetronome() {
    _metronomeTimer?.cancel();
    _metronomeTimer = null;
    setState(() {
      _isMetronomePlaying = false;
    });
  }

  void _playMetronomeTick() {
    // For now, just a visual feedback. You can add actual audio file
    // TODO: Add actual metronome tick sound
  }

  void _toggleRealtimeMonitoring() async {
    if (_realtimeMonitoring) {
      // Enable real-time monitoring
      _recorder!.setSubscriptionDuration(const Duration(milliseconds: 50));
      await _startAudioMonitoring();
    } else {
      // Disable real-time monitoring
      _recorder!.setSubscriptionDuration(const Duration(milliseconds: 1000));
      await _stopAudioMonitoring();
    }
  }

  void _startRecording() async {
    if (_isRecording) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/recording_$timestamp.wav';
      
      // Clear previous waveform data
      _mockWaveform.clear();
      
      // Stop monitoring if it's running
      if (_realtimeMonitoring) {
        await _stopAudioMonitoring();
      }
      
      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.pcm16WAV,
        sampleRate: 44100,
        enableVoiceProcessing: true, // Enable voice processing for better quality
      );
      
      setState(() {
        _isRecording = true;
        _currentRecordingTime = 0.0;
      });
      
      // Start recording timer
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          _currentRecordingTime += 0.1;
          _totalRecordingTime += 0.1;
          _currentBar = _getCurrentBarFromTime(_totalRecordingTime);
        });
        
        // Auto-stop if punch mode and 4 bars completed
        if (_punchMode && _currentRecordingTime >= _getFourBarDuration()) {
          _nextLoop();
        }
      });
      
    } catch (e) {
      print('Recording error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording failed: $e')),
        );
      }
    }
  }

  void _stopRecording() async {
    if (!_isRecording) return;
    
    try {
      await _recorder!.stopRecorder();
      _recordingTimer?.cancel();
      _recordingTimer = null;
      
      if (_currentRecordingPath != null) {
        _audioSegments.add(AudioSegment(
          path: _currentRecordingPath!,
          startTime: _totalRecordingTime - _currentRecordingTime,
          duration: _currentRecordingTime,
        ));
      }
      
      setState(() {
        _isRecording = false;
        _currentRecordingTime = 0.0;
      });
      
      // Restart monitoring if it was enabled
      if (_realtimeMonitoring) {
        await _startAudioMonitoring();
      }
      
    } catch (e) {
      print('Stop recording error: $e');
    }
  }

  void _nextLoop() {
    if (!_isRecording) return;
    
    _stopRecording();
    
    // Start next loop immediately
    Future.delayed(const Duration(milliseconds: 100), () {
      _startRecording();
    });
  }

  void _exportRecording() async {
    if (_audioSegments.isEmpty) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportPath = '${directory.path}/punchio_export_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      // For now, just copy the last segment. In a real implementation,
      // you'd concatenate all segments
      if (_audioSegments.isNotEmpty) {
        final lastSegment = _audioSegments.last;
        await File(lastSegment.path).copy(exportPath);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exported to: $exportPath')),
          );
        }
      }
      
    } catch (e) {
      // TODO: Handle export error properly
    }
  }

  double _getFourBarDuration() {
    // 4 bars = 16 beats at current BPM
    return (16 * 60) / _bpm;
  }

  double _getBarDuration() {
    // 1 bar = 4 beats at current BPM
    return (4 * 60) / _bpm;
  }

  double _getBeatDuration() {
    // 1 beat duration in seconds
    return 60.0 / _bpm;
  }

  double _getPixelsPerBar() {
    // Base pixels per bar, adjusted by zoom level
    return 200.0 * _zoomLevel;
  }

  double _getPixelsPerBeat() {
    return _getPixelsPerBar() / 4.0;
  }

  double _getTotalTimelineWidth() {
    return _totalBars * _getPixelsPerBar();
  }

  int _getCurrentBarFromTime(double timeInSeconds) {
    return (timeInSeconds / _getBarDuration()).floor() + 1;
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel * 1.5).clamp(_minZoom, _maxZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel / 1.5).clamp(_minZoom, _maxZoom);
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
    });
  }

  @override
  void dispose() {
    _metronomeTimer?.cancel();
    _recordingTimer?.cancel();
    _metronomeAnimationController.dispose();
    _recorder?.closeRecorder();
    _player?.closePlayer();
    _metronomePlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Punchio'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // BPM and Metronome Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('BPM: '),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: TextEditingController(text: _bpm.toString()),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final newBpm = int.tryParse(value);
                      if (newBpm != null && newBpm > 0) {
                        setState(() {
                          _bpm = newBpm;
                        });
                      }
                    },
                  ),
                ),
                const Spacer(),
                // Zoom Controls
                Row(
                  children: [
                    IconButton(
                      onPressed: _zoomOut,
                      icon: const Icon(Icons.zoom_out),
                      tooltip: 'Zoom Out',
                    ),
                    Text('${(_zoomLevel * 100).round()}%'),
                    IconButton(
                      onPressed: _zoomIn,
                      icon: const Icon(Icons.zoom_in),
                      tooltip: 'Zoom In',
                    ),
                    IconButton(
                      onPressed: _resetZoom,
                      icon: const Icon(Icons.center_focus_strong),
                      tooltip: 'Reset Zoom',
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isMetronomePlaying ? _stopMetronome : _startMetronome,
                  child: Text(_isMetronomePlaying ? 'Stop' : 'Start'),
                ),
              ],
            ),
          ),
          
          // Recording Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                // Record Button
                ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  label: Text(_isRecording ? 'Stop' : 'Record'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                // Punch Mode Toggle
                Column(
                  children: [
                    const Text('Punch Mode'),
                    Switch(
                      value: _punchMode,
                      onChanged: (value) {
                        setState(() {
                          _punchMode = value;
                        });
                      },
                    ),
                  ],
                ),
                
                // Real-time Monitoring Toggle
                Column(
                  children: [
                    const Text('Monitor'),
                    Container(
                      decoration: BoxDecoration(
                        color: _realtimeMonitoring ? Colors.green[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _realtimeMonitoring ? Colors.green : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Switch(
                        value: _realtimeMonitoring,
                        onChanged: (value) {
                          setState(() {
                            _realtimeMonitoring = value;
                          });
                          _toggleRealtimeMonitoring();
                        },
                      ),
                    ),
                    Text(
                      _realtimeMonitoring ? 'ON' : 'OFF',
                      style: TextStyle(
                        color: _realtimeMonitoring ? Colors.green[700] : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                // Next Button
                ElevatedButton(
                  onPressed: _isRecording && _punchMode ? _nextLoop : null,
                  child: const Text('Next'),
                ),
                
                // Export Button
                ElevatedButton(
                  onPressed: _audioSegments.isNotEmpty ? _exportRecording : null,
                  child: const Text('Export'),
                ),
                ],
              ),
            ),
          ),
          
          // Metronome Visual Indicator
          if (_isMetronomePlaying)
            AnimatedBuilder(
              animation: _metronomeAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _metronomeAnimation.value,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          
          const SizedBox(height: 20),
          
          // Bar Counter and Timeline Info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bar: $_currentBar',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'Time: ${_totalRecordingTime.toStringAsFixed(1)}s',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'BPM: $_bpm',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _realtimeMonitoring ? Colors.green[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _realtimeMonitoring ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Text(
                    _realtimeMonitoring ? 'MONITORING' : 'NO MONITOR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _realtimeMonitoring ? Colors.green[700] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
                     const SizedBox(height: 20),
           
           // Monitoring Help Text
           if (_realtimeMonitoring)
             Container(
               margin: const EdgeInsets.symmetric(horizontal: 16.0),
               padding: const EdgeInsets.all(12.0),
               decoration: BoxDecoration(
                 color: Colors.green[50],
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: Colors.green[200]!),
               ),
               child: Text(
                 '🎧 Ultra-Low Latency Monitoring ON (${_currentLatency.toStringAsFixed(1)}ms)\nYou should hear yourself with minimal echo!',
                 style: const TextStyle(
                   fontSize: 12,
                   color: Colors.green,
                   fontWeight: FontWeight.bold,
                 ),
                 textAlign: TextAlign.center,
               ),
             ),
           
           const SizedBox(height: 20),
           
           // Real-time Audio Level Indicator
          if (_isRecording)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: Column(
                children: [
                  const Text('Audio Level', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Level: '),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (_currentAudioLevel / 100).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _currentAudioLevel > 80 ? Colors.red :
                            _currentAudioLevel > 50 ? Colors.orange : Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${_currentAudioLevel.toStringAsFixed(1)} dB'),
                    ],
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 20),
          
          // DAW Timeline Grid
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Timeline Header
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('DAW Timeline'),
                        const Spacer(),
                        Text('Zoom: ${(_zoomLevel * 100).round()}%'),
                      ],
                    ),
                  ),
                  
                  // DAW Grid Display
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _timelineScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: max(MediaQuery.of(context).size.width - 32, _getTotalTimelineWidth()),
                        height: 300,
                        child: CustomPaint(
                          painter: DAWGridPainter(
                            currentTime: _totalRecordingTime,
                            currentBar: _currentBar,
                            bpm: _bpm,
                            zoomLevel: _zoomLevel,
                            pixelsPerBar: _getPixelsPerBar(),
                            pixelsPerBeat: _getPixelsPerBeat(),
                            totalBars: _totalBars,
                            waveform: _mockWaveform,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AudioSegment {
  final String path;
  final double startTime;
  final double duration;

  AudioSegment({
    required this.path,
    required this.startTime,
    required this.duration,
  });
}

class DAWGridPainter extends CustomPainter {
  final double currentTime;
  final int currentBar;
  final int bpm;
  final double zoomLevel;
  final double pixelsPerBar;
  final double pixelsPerBeat;
  final int totalBars;
  final List<double> waveform;

  DAWGridPainter({
    required this.currentTime,
    required this.currentBar,
    required this.bpm,
    required this.zoomLevel,
    required this.pixelsPerBar,
    required this.pixelsPerBeat,
    required this.totalBars,
    required this.waveform,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final waveformHeight = size.height * 0.6;
    final gridHeight = size.height * 0.4;

    // Draw background
    final backgroundPaint = Paint()
      ..color = Colors.grey[50]!
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Draw DAW grid lines
    _drawDAWGrid(canvas, size, gridHeight);

    // Draw bar numbers
    _drawBarNumbers(canvas, size, gridHeight);

    // Draw waveform
    _drawWaveform(canvas, size, centerY, waveformHeight);

    // Draw current time indicator
    _drawTimeIndicator(canvas, size);

    // Draw beat markers
    _drawBeatMarkers(canvas, size, gridHeight);
  }

  void _drawDAWGrid(Canvas canvas, Size size, double gridHeight) {
    final majorGridPaint = Paint()
      ..color = Colors.blue[300]!
      ..strokeWidth = 2.0;

    final minorGridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.0;

    // Draw vertical bar lines (major grid)
    for (int bar = 0; bar <= totalBars; bar++) {
      final x = bar * pixelsPerBar;
      if (x <= size.width) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          majorGridPaint,
        );
      }
    }

    // Draw beat lines (minor grid)
    for (int bar = 0; bar < totalBars; bar++) {
      for (int beat = 1; beat < 4; beat++) {
        final x = (bar * pixelsPerBar) + (beat * pixelsPerBeat);
        if (x <= size.width) {
          canvas.drawLine(
            Offset(x, 0),
            Offset(x, size.height),
            minorGridPaint,
          );
        }
      }
    }

    // Draw horizontal center line
    final centerLinePaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerLinePaint,
    );
  }

  void _drawBarNumbers(Canvas canvas, Size size, double gridHeight) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int bar = 1; bar <= totalBars; bar++) {
      final x = (bar - 1) * pixelsPerBar + 5;
      if (x < size.width - 30) {
        textPainter.text = TextSpan(
          text: bar.toString(),
          style: TextStyle(
            color: bar == currentBar ? Colors.red : Colors.blue[700],
            fontSize: 14,
            fontWeight: bar == currentBar ? FontWeight.bold : FontWeight.normal,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x, 5));
      }
    }
  }

  void _drawWaveform(Canvas canvas, Size size, double centerY, double waveformHeight) {
    if (waveform.isEmpty) return;

    final barWidth = 2.0;
    final barSpacing = 1.0;
    final maxHeight = waveformHeight * 0.8;

    // Draw waveform bars
    for (int i = 0; i < waveform.length; i++) {
      final x = i * (barWidth + barSpacing);
      if (x >= size.width) break;
      
      final amplitude = waveform[i];
      final height = (amplitude / 100.0) * maxHeight;
      
      // Color based on amplitude
      Color barColor;
      if (amplitude < 30) {
        barColor = Colors.green[400]!;
      } else if (amplitude < 70) {
        barColor = Colors.orange[400]!;
      } else {
        barColor = Colors.red[400]!;
      }
      
      final paint = Paint()
        ..color = barColor
        ..strokeWidth = barWidth
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(
          x,
          centerY - height / 2,
          barWidth,
          height,
        ),
        paint,
      );
    }
  }

  void _drawTimeIndicator(Canvas canvas, Size size) {
    final barDuration = (4 * 60) / bpm; // 4 beats per bar
    final currentBarTime = (currentBar - 1) * barDuration;
    final timeInCurrentBar = currentTime - currentBarTime;
    final x = ((currentBar - 1) * pixelsPerBar) + (timeInCurrentBar / barDuration) * pixelsPerBar;

    if (x >= 0 && x <= size.width) {
      final indicatorPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 3.0;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        indicatorPaint,
      );

      // Draw time indicator triangle
      final trianglePaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(x - 5, 0);
      path.lineTo(x + 5, 0);
      path.lineTo(x, 10);
      path.close();
      canvas.drawPath(path, trianglePaint);
    }
  }

  void _drawBeatMarkers(Canvas canvas, Size size, double gridHeight) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int bar = 0; bar < totalBars; bar++) {
      for (int beat = 1; beat <= 4; beat++) {
        final x = (bar * pixelsPerBar) + ((beat - 1) * pixelsPerBeat) + 2;
        if (x < size.width - 10) {
          textPainter.text = TextSpan(
            text: beat.toString(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(x, gridHeight + 5));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}