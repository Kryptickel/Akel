import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/evidence_service.dart';
import '../services/vibration_service.dart';

class EvidenceScreen extends StatefulWidget {
  const EvidenceScreen({super.key});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  final EvidenceService _evidenceService = EvidenceService();
  final VibrationService _vibrationService = VibrationService();

  List<Evidence> _evidence = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  bool _isRecording = false;
  EvidenceType _recordingType = EvidenceType.audio;

  @override
  void initState() {
    super.initState();
    _loadEvidence();
    _loadStatistics();
  }

  @override
  void dispose() {
    _evidenceService.dispose();
    super.dispose();
  }

  Future<void> _loadEvidence() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final evidence = await _evidenceService.getEvidence(userId);

        if (mounted) {
          setState(() {
            _evidence = evidence;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint(' Load evidence error: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStatistics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final stats = await _evidenceService.getEvidenceStatistics(userId);

        if (mounted) {
          setState(() {
            _statistics = stats;
          });
        }
      } catch (e) {
        debugPrint(' Load statistics error: $e');
      }
    }
  }

  Future<void> _startRecording(EvidenceType type) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    await _vibrationService.light();

    setState(() {
      _isRecording = true;
      _recordingType = type;
    });

    // Create a temporary panic event ID for testing
    final tempEventId = 'test_${DateTime.now().millisecondsSinceEpoch}';

    if (type == EvidenceType.audio) {
      await _evidenceService.startAudioRecording(userId, tempEventId);
    } else if (type == EvidenceType.video) {
      await _evidenceService.startVideoRecording(userId, tempEventId);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                type == EvidenceType.audio ? Icons.mic : Icons.videocam,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text('Recording ${type == EvidenceType.audio ? 'audio' : 'video'}...'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(days: 1),
          action: SnackBarAction(
            label: 'STOP',
            textColor: Colors.white,
            onPressed: _stopRecording,
          ),
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    Evidence? evidence;
    if (_recordingType == EvidenceType.audio) {
      evidence = await _evidenceService.stopAudioRecording(userId);
    } else if (_recordingType == EvidenceType.video) {
      evidence = await _evidenceService.stopVideoRecording(userId);
    }

    setState(() => _isRecording = false);

    if (evidence != null && mounted) {
      await _vibrationService.success();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ' ${EvidenceService.getTypeLabel(_recordingType)} recorded successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _loadEvidence();
      _loadStatistics();
    } else if (mounted) {
      await _vibrationService.error();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Recording failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadEvidence(Evidence evidence) async {
    await _vibrationService.light();

    if (evidence.isUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Already uploaded'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Uploading evidence...'),
          ],
        ),
      ),
    );

    final success = await _evidenceService.uploadEvidence(evidence.id);

    if (mounted) {
      Navigator.pop(context);

      if (success) {
        await _vibrationService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Evidence uploaded'),
            backgroundColor: Colors.green,
          ),
        );
        _loadEvidence();
      } else {
        await _vibrationService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Upload failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteEvidence(Evidence evidence) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Evidence?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await _evidenceService.deleteEvidence(evidence.id);

      if (success && mounted) {
        await _vibrationService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Evidence deleted'),
            backgroundColor: Colors.green,
          ),
        );
        _loadEvidence();
        _loadStatistics();
      }
    }
  }

  void _playAudio(Evidence evidence) async {
    await _vibrationService.light();

    final player = AudioPlayer();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.audiotrack, color: Colors.purple),
            SizedBox(width: 12),
            Text('Audio Player'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              evidence.localPath.split('/').last,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Duration: ${_evidenceService.formatDuration(evidence.durationSeconds)}',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await player.play(DeviceFileSource(evidence.localPath));
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              player.stop();
              player.dispose();
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _playVideo(Evidence evidence) async {
    await _vibrationService.light();

    final controller = VideoPlayerController.file(File(evidence.localPath));
    await controller.initialize();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.videocam, color: Colors.red),
            SizedBox(width: 12),
            Text('Video Player'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  onPressed: () {
                    setState(() {
                      controller.value.isPlaying
                          ? controller.pause()
                          : controller.play();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evidence Recording'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _vibrationService.light();
              _loadEvidence();
              _loadStatistics();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          if (_statistics != null) _buildStatisticsCard(),

          // Info Card
          _buildInfoCard(),

          // Evidence List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _evidence.isEmpty
                ? _buildEmptyState()
                : _buildEvidenceList(),
          ),
        ],
      ),
      floatingActionButton: _isRecording
          ? FloatingActionButton.extended(
        onPressed: _stopRecording,
        icon: const Icon(Icons.stop),
        label: const Text('Stop Recording'),
        backgroundColor: Colors.red,
      )
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'video',
            onPressed: () => _startRecording(EvidenceType.video),
            backgroundColor: Colors.red,
            child: const Icon(Icons.videocam),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'audio',
            onPressed: () => _startRecording(EvidenceType.audio),
            backgroundColor: Colors.purple,
            child: const Icon(Icons.mic),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final total = _statistics!['totalEvidence'] as int;
    final audio = _statistics!['audioEvidence'] as int;
    final video = _statistics!['videoEvidence'] as int;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple,
            Colors.purple.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', '$total', Icons.folder),
          _buildStatItem('Audio', '$audio', Icons.audiotrack),
          _buildStatItem('Video', '$video', Icons.videocam),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.purple, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Evidence Recording',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Record audio/video evidence during emergencies.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Evidence Recorded',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Record audio or video evidence',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _startRecording(EvidenceType.audio),
                icon: const Icon(Icons.mic),
                label: const Text('Record Audio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _startRecording(EvidenceType.video),
                icon: const Icon(Icons.videocam),
                label: const Text('Record Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _evidence.length,
      itemBuilder: (context, index) {
        final evidence = _evidence[index];
        return _buildEvidenceCard(evidence);
      },
    );
  }

  Widget _buildEvidenceCard(Evidence evidence) {
    final typeColor = _hexToColor(EvidenceService.getTypeColor(evidence.type));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: InkWell(
        onTap: () {
          _vibrationService.light();
          if (evidence.type == EvidenceType.audio) {
            _playAudio(evidence);
          } else if (evidence.type == EvidenceType.video) {
            _playVideo(evidence);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Type Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        EvidenceService.getTypeIcon(evidence.type),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Evidence Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          EvidenceService.getTypeLabel(evidence.type),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy hh:mm a').format(evidence.timestamp),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Upload Status
                  if (evidence.isUploaded)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_done, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            'UPLOADED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Details Row
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _evidenceService.formatDuration(evidence.durationSeconds),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.storage, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _evidenceService.formatFileSize(evidence.fileSizeBytes),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  if (!evidence.isUploaded)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _uploadEvidence(evidence),
                        icon: const Icon(Icons.cloud_upload, size: 16),
                        label: const Text('Upload'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  if (!evidence.isUploaded) const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteEvidence(evidence),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
  }
}