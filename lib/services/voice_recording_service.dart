import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VoiceRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;

  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentRecordingPath => _currentRecordingPath;

  // Check microphone permission
  Future<bool> checkPermission() async {
    if (kIsWeb) {
      // Web handles permissions automatically
      return true;
    }

    final status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }

    return false;
  }

  // Start recording
  Future<bool> startRecording() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        debugPrint(' Microphone permission denied');
        return false;
      }

      // Check if already recording
      if (_isRecording) {
        debugPrint(' Already recording');
        return false;
      }

      // Generate file path
      final directory = kIsWeb
          ? null
          : await getApplicationDocumentsDirectory();

      final fileName = 'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = kIsWeb
          ? fileName
          : '${directory!.path}/$fileName';

      // Start recording
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      debugPrint(' Recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      debugPrint(' Start recording error: $e');
      return false;
    }
  }

  // Stop recording
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        debugPrint(' Not currently recording');
        return null;
      }

      final path = await _recorder.stop();
      _isRecording = false;

      if (path != null) {
        _currentRecordingPath = path;
        debugPrint(' Recording stopped: $path');
        return path;
      }

      return null;
    } catch (e) {
      debugPrint(' Stop recording error: $e');
      _isRecording = false;
      return null;
    }
  }

  // Cancel recording (stop and delete)
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
      }

      if (_currentRecordingPath != null && !kIsWeb) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint(' Recording deleted');
        }
      }

      _currentRecordingPath = null;
    } catch (e) {
      debugPrint(' Cancel recording error: $e');
    }
  }

  // Play recording
  Future<bool> playRecording(String path) async {
    try {
      if (_isPlaying) {
        await _player.stop();
      }

      await _player.play(DeviceFileSource(path));
      _isPlaying = true;

      // Listen for completion
      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
      });

      debugPrint(' Playing recording: $path');
      return true;
    } catch (e) {
      debugPrint(' Play recording error: $e');
      return false;
    }
  }

  // Stop playback
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
      _isPlaying = false;
      debugPrint(' Playback stopped');
    } catch (e) {
      debugPrint(' Stop playback error: $e');
    }
  }

  // Get recording duration
  Future<Duration?> getRecordingDuration(String path) async {
    try {
      await _player.setSourceDeviceFile(path);
      final duration = await _player.getDuration();
      return duration;
    } catch (e) {
      debugPrint(' Get duration error: $e');
      return null;
    }
  }

  // Save voice note to panic event
  Future<bool> attachVoiceNoteToEvent({
    required String eventId,
    required String voiceNotePath,
  }) async {
    try {
      final duration = await getRecordingDuration(voiceNotePath);

      await FirebaseFirestore.instance
          .collection('panic_events')
          .doc(eventId)
          .update({
        'voiceNote': {
          'path': voiceNotePath,
          'timestamp': FieldValue.serverTimestamp(),
          'duration': duration?.inSeconds ?? 0,
        }
      });

      debugPrint(' Voice note attached to event: $eventId');
      return true;
    } catch (e) {
      debugPrint(' Attach voice note error: $e');
      return false;
    }
  }

  // Get voice note from event
  Future<Map<String, dynamic>?> getVoiceNoteFromEvent(String eventId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('panic_events')
          .doc(eventId)
          .get();

      final data = doc.data();
      if (data != null && data.containsKey('voiceNote')) {
        return data['voiceNote'] as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      debugPrint(' Get voice note error: $e');
      return null;
    }
  }

  // Format duration for display
  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Dispose
  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}