import 'package:flutter/material.dart';
import 'dart:async';

class EvidenceRecordingScreen extends StatefulWidget {
  const EvidenceRecordingScreen({super.key});

  @override
  State<EvidenceRecordingScreen> createState() =>
      _EvidenceRecordingScreenState();
}

class _EvidenceRecordingScreenState extends State<EvidenceRecordingScreen> {
  bool _isRecording = false;
  bool _isAudioOnly = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  final List<RecordingItem> _recordings = [];

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Evidence Recording'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => _showSettings(),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        children: [
// Recording Control Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isRecording
                    ? [const Color(0xFFDC143C), const Color(0xFFFF1744)]
                    : [const Color(0xFF1E2740), const Color(0xFF2A3654)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (_isRecording)
                  BoxShadow(
                    color: const Color(0xFFDC143C).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Column(
              children: [
// Recording Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isRecording
                        ? Icons.stop
                        : (_isAudioOnly ? Icons.mic : Icons.videocam),
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),

// Status Text
                Text(
                  _isRecording ? 'Recording...' : 'Ready to Record',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

// Timer
                if (_isRecording)
                  Text(
                    _formatDuration(_recordingSeconds),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 32,
                      fontFamily: 'monospace',
                    ),
                  ),

                const SizedBox(height: 24),

// Mode Toggle
                if (!_isRecording)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildModeButton(
                        'Video',
                        Icons.videocam,
                        !_isAudioOnly,
                            () => setState(() => _isAudioOnly = false),
                      ),
                      const SizedBox(width: 16),
                      _buildModeButton(
                        'Audio',
                        Icons.mic,
                        _isAudioOnly,
                            () => setState(() => _isAudioOnly = true),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

// Record Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    icon: Icon(
                      _isRecording ? Icons.stop : Icons.fiber_manual_record,
                      size: 28,
                    ),
                    label: Text(
                      _isRecording ? 'Stop Recording' : 'Start Recording',
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording
                          ? Colors.white
                          : const Color(0xFFDC143C),
                      foregroundColor: _isRecording
                          ? const Color(0xFFDC143C)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

// Features Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2740),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildFeatureItem(
                    Icons.cloud_upload,
                    'Auto Cloud Backup',
                    'Recordings saved securely',
                  ),
                  const Divider(color: Colors.white12),
                  _buildFeatureItem(
                    Icons.lock,
                    'Encrypted Storage',
                    'Military-grade encryption',
                  ),
                  const Divider(color: Colors.white12),
                  _buildFeatureItem(
                    Icons.share,
                    'Easy Sharing',
                    'Share with authorities',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

// Recordings List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Recordings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
// View all recordings
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),

// Recordings List
          Expanded(
            child: _recordings.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recordings yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recordings.length,
              itemBuilder: (context, index) {
                final recording = _recordings[index];
                return _buildRecordingCard(recording);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
      String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white24,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00BFA5), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(RecordingItem recording) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: recording.isVideo
                  ? Colors.blue.withValues(alpha: 0.2)
                  : Colors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              recording.isVideo ? Icons.videocam : Icons.mic,
              color: recording.isVideo ? Colors.blue : Colors.purple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recording.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_formatDuration(recording.duration)} • ${_formatDateTime(recording.timestamp)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _shareRecording(recording),
            icon: const Icon(Icons.share, color: Color(0xFF00BFA5)),
          ),
        ],
      ),
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingSeconds++;
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎥 ${_isAudioOnly ? "Audio" : "Video"} recording started',
        ),
        backgroundColor: const Color(0xFFDC143C),
      ),
    );
  }

  void _stopRecording() {
    _recordingTimer?.cancel();

    final recording = RecordingItem(
      name: '${_isAudioOnly ? "Audio" : "Video"} ${DateTime.now().toString().substring(0, 19)}',
      timestamp: DateTime.now(),
      duration: _recordingSeconds,
      isVideo: !_isAudioOnly,
    );

    setState(() {
      _isRecording = false;
      _recordings.insert(0, recording);
      _recordingSeconds = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Recording saved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareRecording(RecordingItem recording) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Share Recording',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              recording.name,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share this recording with:',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📤 Sharing with emergency contacts...'),
                ),
              );
            },
            icon: const Icon(Icons.contacts),
            label: const Text('Emergency Contacts'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Recording Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text(
                'Auto-Start on Panic',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Start recording when panic button pressed',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              value: true,
              onChanged: (value) {},
              activeColor: const Color(0xFF00BFA5),
            ),
            SwitchListTile(
              title: const Text(
                'Cloud Backup',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Automatically backup to cloud',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              value: true,
              onChanged: (value) {},
              activeColor: const Color(0xFF00BFA5),
            ),
            SwitchListTile(
              title: const Text(
                'High Quality',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                '1080p video recording',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              value: false,
              onChanged: (value) {},
              activeColor: const Color(0xFF00BFA5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class RecordingItem {
  final String name;
  final DateTime timestamp;
  final int duration;
  final bool isVideo;

  RecordingItem({
    required this.name,
    required this.timestamp,
    required this.duration,
    required this.isVideo,
  });
}