import 'package:flutter/material.dart';
import 'dart:async';
import '../services/voice_recording_service.dart';
import '../services/vibration_service.dart';

class VoiceRecordingWidget extends StatefulWidget {
  final Function(String voiceNotePath)? onRecordingComplete;
  final int maxDurationSeconds;

  const VoiceRecordingWidget({
    super.key,
    this.onRecordingComplete,
    this.maxDurationSeconds = 60,
  });

  @override
  State<VoiceRecordingWidget> createState() => _VoiceRecordingWidgetState();
}

class _VoiceRecordingWidgetState extends State<VoiceRecordingWidget> {
  final VoiceRecordingService _voiceService = VoiceRecordingService();
  final VibrationService _vibrationService = VibrationService();

  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isPlaying = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  String? _recordingPath;

  @override
  void dispose() {
    _timer?.cancel();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    await _vibrationService.light();

    final started = await _voiceService.startRecording();
    if (started) {
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
        _hasRecording = false;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });

// Auto-stop at max duration
        if (_recordingSeconds >= widget.maxDurationSeconds) {
          _stopRecording();
        }
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Microphone permission required'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    await _vibrationService.success();
    _timer?.cancel();

    final path = await _voiceService.stopRecording();

    setState(() {
      _isRecording = false;
      _hasRecording = path != null;
      _recordingPath = path;
    });

    if (path != null && widget.onRecordingComplete != null) {
      widget.onRecordingComplete!(path);
    }
  }

  Future<void> _cancelRecording() async {
    await _vibrationService.warning();
    _timer?.cancel();

    await _voiceService.cancelRecording();

    setState(() {
      _isRecording = false;
      _hasRecording = false;
      _recordingPath = null;
      _recordingSeconds = 0;
    });
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;

    await _vibrationService.light();

    if (_isPlaying) {
      await _voiceService.stopPlayback();
      setState(() => _isPlaying = false);
    } else {
      final playing = await _voiceService.playRecording(_recordingPath!);
      setState(() => _isPlaying = playing);
    }
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isRecording
              ? Colors.red
              : Theme.of(context).dividerColor,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
// Title
          Row(
            children: [
              Icon(
                Icons.mic,
                color: _isRecording ? Colors.red : Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                _isRecording
                    ? 'Recording...'
                    : _hasRecording
                    ? 'Voice Note Ready'
                    : 'Record Voice Note',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

// Recording timer or waveform
          if (_isRecording) ...[
// Animated waveform
            SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  20,
                      (index) => AnimatedContainer(
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    curve: Curves.easeInOut,
                    width: 4,
                    height: 10 + (index % 3) * 15.0,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

// Timer
            Text(
              _formatTime(_recordingSeconds),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.maxDurationSeconds - _recordingSeconds}s remaining',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ] else if (_hasRecording) ...[
// Playback UI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _playRecording,
                    icon: Icon(
                      _isPlaying ? Icons.stop : Icons.play_arrow,
                      size: 32,
                    ),
                    color: Colors.green,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPlaying ? 'Playing...' : 'Tap to preview',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatTime(_recordingSeconds),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
// Initial state
            Icon(
              Icons.mic_none,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to start recording',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],

          const SizedBox(height: 20),

// Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_isRecording) ...[
// Cancel button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cancelRecording,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

// Stop button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _stopRecording,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ] else if (_hasRecording) ...[
// Re-record button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _cancelRecording();
                      _startRecording();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Re-record'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

// Done button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, _recordingPath),
                    icon: const Icon(Icons.check),
                    label: const Text('Use This'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ] else ...[
// Start recording button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startRecording,
                    icon: const Icon(Icons.mic),
                    label: const Text('Start Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}