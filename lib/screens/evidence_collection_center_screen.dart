import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import '../widgets/futuristic_widgets.dart';
import '../services/evidence_collection_service.dart';
import '../providers/auth_provider.dart';

/// ==================== EVIDENCE COLLECTION CENTER SCREEN ====================
///
/// 4-IN-1 EVIDENCE CENTER:
/// 1. Photo Evidence - Quick photo capture
/// 2. Audio Recording - Background audio
/// 3. Video Recording - Stealth video
/// 4. Evidence Vault - Encrypted storage
///
/// BUILD 55 - HOUR 10
/// ================================================================

class EvidenceCollectionCenterScreen extends StatefulWidget {
  const EvidenceCollectionCenterScreen({Key? key}) : super(key: key);

  @override
  State<EvidenceCollectionCenterScreen> createState() => _EvidenceCollectionCenterScreenState();
}

class _EvidenceCollectionCenterScreenState extends State<EvidenceCollectionCenterScreen>
    with TickerProviderStateMixin {
  final EvidenceCollectionService _evidenceService = EvidenceCollectionService();

  late TabController _tabController;
  late AnimationController _recordingAnimController;

  bool _isInitializing = true;
  bool _isRecordingAudio = false;
  bool _isRecordingVideo = false;

  List<EvidenceItem> _evidenceItems = [];
  Map<String, int> _stats = {};

  Duration _audioRecordingDuration = Duration.zero;
  Duration _videoRecordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _recordingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _initializeService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recordingAnimController.dispose();
    _evidenceService.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    setState(() => _isInitializing = true);

    try {
      final initialized = await _evidenceService.initialize();

      if (!initialized) {
        _showError('Failed to initialize evidence service');
        setState(() => _isInitializing = false);
        return;
      }

      await _loadEvidence();
      await _loadStats();

      setState(() => _isInitializing = false);
    } catch (e) {
      debugPrint(' Evidence initialization error: $e');
      setState(() => _isInitializing = false);
      _showError('Initialization failed: $e');
    }
  }

  Future<void> _loadEvidence() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      final evidence = await _evidenceService.getEvidence(userId);
      if (mounted) {
        setState(() {
          _evidenceItems = evidence;
        });
      }
    }
  }

  Future<void> _loadStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      final stats = await _evidenceService.getEvidenceStats(userId);
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    }
  }

  // ==================== PHOTO CAPTURE ====================

  Future<void> _capturePhoto() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      _showError('Please log in');
      return;
    }

    try {
      final description = await _showDescriptionDialog('Photo Evidence');
      if (description == null) return;

      final evidence = await _evidenceService.capturePhoto(
        userId: userId,
        description: description,
        metadata: {
          'capturedAt': DateTime.now().toIso8601String(),
        },
      );

      if (evidence != null) {
        await _loadEvidence();
        await _loadStats();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(' Photo evidence captured'),
              backgroundColor: AkelDesign.successGreen,
            ),
          );
        }
      } else {
        _showError('Failed to capture photo');
      }
    } catch (e) {
      debugPrint(' Photo capture error: $e');
      _showError('Photo capture failed: $e');
    }
  }

  // ==================== AUDIO RECORDING ====================

  Future<void> _toggleAudioRecording() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      _showError('Please log in');
      return;
    }

    if (_isRecordingAudio) {
      // Stop recording
      try {
        final description = await _showDescriptionDialog('Audio Evidence');
        if (description == null) {
          // User cancelled - still stop recording
          await _evidenceService.stopAudioRecording(
            userId: userId,
            description: 'Audio evidence (no description)',
          );
          setState(() => _isRecordingAudio = false);
          return;
        }

        final evidence = await _evidenceService.stopAudioRecording(
          userId: userId,
          description: description,
          metadata: {
            'duration': _audioRecordingDuration.inSeconds,
          },
        );

        setState(() => _isRecordingAudio = false);
        _audioRecordingDuration = Duration.zero;

        if (evidence != null) {
          await _loadEvidence();
          await _loadStats();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(' Audio evidence saved'),
                backgroundColor: AkelDesign.successGreen,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint(' Audio stop error: $e');
        _showError('Failed to save audio');
        setState(() => _isRecordingAudio = false);
      }
    } else {
      // Start recording
      try {
        final started = await _evidenceService.startAudioRecording(
          userId: userId,
          description: 'Audio evidence',
        );

        if (started) {
          setState(() => _isRecordingAudio = true);
          _startAudioTimer();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(' Audio recording started'),
              backgroundColor: AkelDesign.infoBlue,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          _showError('Failed to start recording');
        }
      } catch (e) {
        debugPrint(' Audio start error: $e');
        _showError('Failed to start recording: $e');
      }
    }
  }

  void _startAudioTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecordingAudio && mounted) {
        setState(() {
          _audioRecordingDuration += const Duration(seconds: 1);
        });
        _startAudioTimer();
      }
    });
  }

  // ==================== VIDEO RECORDING ====================

  Future<void> _toggleVideoRecording() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      _showError('Please log in');
      return;
    }

    if (_isRecordingVideo) {
      // Stop recording
      try {
        final description = await _showDescriptionDialog('Video Evidence');
        if (description == null) {
          await _evidenceService.stopVideoRecording(
            userId: userId,
            description: 'Video evidence (no description)',
          );
          setState(() => _isRecordingVideo = false);
          return;
        }

        final evidence = await _evidenceService.stopVideoRecording(
          userId: userId,
          description: description,
          metadata: {
            'duration': _videoRecordingDuration.inSeconds,
          },
        );

        setState(() => _isRecordingVideo = false);
        _videoRecordingDuration = Duration.zero;

        if (evidence != null) {
          await _loadEvidence();
          await _loadStats();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(' Video evidence saved'),
                backgroundColor: AkelDesign.successGreen,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint(' Video stop error: $e');
        _showError('Failed to save video');
        setState(() => _isRecordingVideo = false);
      }
    } else {
      // Start recording
      try {
        final started = await _evidenceService.startVideoRecording(
          userId: userId,
          description: 'Video evidence',
          stealthMode: false,
        );

        if (started) {
          setState(() => _isRecordingVideo = true);
          _startVideoTimer();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(' Video recording started'),
              backgroundColor: AkelDesign.infoBlue,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          _showError('Failed to start recording');
        }
      } catch (e) {
        debugPrint(' Video start error: $e');
        _showError('Failed to start recording: $e');
      }
    }
  }

  void _startVideoTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecordingVideo && mounted) {
        setState(() {
          _videoRecordingDuration += const Duration(seconds: 1);
        });
        _startVideoTimer();
      }
    });
  }

  // ==================== DIALOGS ====================

  Future<String?> _showDescriptionDialog(String title) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
        ),
        title: Text(title, style: AkelDesign.h3),
        content: TextField(
          controller: controller,
          style: AkelDesign.body,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add description (optional)',
            hintStyle: AkelDesign.caption,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
              borderSide: BorderSide(color: AkelDesign.neonBlue.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
              borderSide: const BorderSide(color: AkelDesign.neonBlue),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AkelDesign.caption),
          ),
          FuturisticButton(
            text: 'Save',
            onPressed: () {
              Navigator.pop(context, controller.text.isEmpty ? 'Evidence' : controller.text);
            },
            isSmall: true,
            color: AkelDesign.successGreen,
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AkelDesign.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: AkelDesign.deepBlack,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FuturisticLoadingIndicator(
                size: 60,
                color: AkelDesign.neonBlue,
              ),
              SizedBox(height: AkelDesign.xl),
              Text(
                'Initializing Evidence Center...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AkelDesign.deepBlack,
      appBar: AppBar(
        backgroundColor: AkelDesign.carbonFiber,
        elevation: 0,
        leading: FuturisticIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
          size: 40,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EVIDENCE CENTER',
              style: AkelDesign.h3.copyWith(fontSize: 16),
            ),
            Text(
              '4-in-1 Evidence Collection',
              style: AkelDesign.caption.copyWith(fontSize: 10),
            ),
          ],
        ),
        actions: [
          if (_isRecordingAudio || _isRecordingVideo)
            Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedBuilder(
                animation: _recordingAnimController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.3 + (_recordingAnimController.value * 0.7),
                    child: const Icon(
                      Icons.fiber_manual_record,
                      color: AkelDesign.primaryRed,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AkelDesign.neonBlue,
          labelColor: AkelDesign.neonBlue,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Photo'),
            Tab(text: 'Audio'),
            Tab(text: 'Video'),
            Tab(text: 'Vault'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPhotoTab(),
          _buildAudioTab(),
          _buildVideoTab(),
          _buildVaultTab(),
        ],
      ),
    );
  }

  // ==================== TAB 1: PHOTO EVIDENCE ====================

  Widget _buildPhotoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        children: [
          // Capture Button
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.xxl),
            hasGlow: true,
            glowColor: AkelDesign.neonBlue,
            child: Column(
              children: [
                const Icon(
                  Icons.camera_alt,
                  size: 80,
                  color: AkelDesign.neonBlue,
                ),
                const SizedBox(height: AkelDesign.lg),
                Text(
                  'PHOTO EVIDENCE',
                  style: AkelDesign.h3.copyWith(color: AkelDesign.neonBlue),
                ),
                const SizedBox(height: AkelDesign.md),
                Text(
                  'Capture photo evidence with timestamp',
                  style: AkelDesign.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AkelDesign.xl),
                FuturisticButton(
                  text: 'CAPTURE PHOTO',
                  icon: Icons.camera,
                  onPressed: _capturePhoto,
                  color: AkelDesign.neonBlue,
                  isFullWidth: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.xl),

          // Statistics
          Text('PHOTO STATISTICS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Photos',
                  '${_stats['photos'] ?? 0}',
                  Icons.photo_library,
                  AkelDesign.neonBlue,
                ),
              ),
              const SizedBox(width: AkelDesign.md),
              Expanded(
                child: _buildStatCard(
                  'Total Items',
                  '${_stats['total'] ?? 0}',
                  Icons.folder,
                  AkelDesign.successGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: AkelDesign.xl),

          // Info
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: AkelDesign.infoBlue, size: 20),
                    const SizedBox(width: AkelDesign.md),
                    Text('HOW IT WORKS', style: AkelDesign.subtitle.copyWith(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: AkelDesign.md),
                _buildInfoStep('1', 'Tap "Capture Photo" button'),
                _buildInfoStep('2', 'Add optional description'),
                _buildInfoStep('3', 'Photo saved with timestamp and metadata'),
                _buildInfoStep('4', 'Access from Evidence Vault'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 2: AUDIO RECORDING ====================

  Widget _buildAudioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        children: [
          // Recording Interface
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.xxl),
            hasGlow: _isRecordingAudio,
            glowColor: AkelDesign.primaryRed,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _recordingAnimController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRecordingAudio ? 1.0 + (_recordingAnimController.value * 0.1) : 1.0,
                      child: Icon(
                        _isRecordingAudio ? Icons.mic : Icons.mic_none,
                        size: 80,
                        color: _isRecordingAudio ? AkelDesign.primaryRed : AkelDesign.neonBlue,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AkelDesign.lg),
                Text(
                  _isRecordingAudio ? 'RECORDING...' : 'AUDIO EVIDENCE',
                  style: AkelDesign.h3.copyWith(
                    color: _isRecordingAudio ? AkelDesign.primaryRed : AkelDesign.neonBlue,
                  ),
                ),
                const SizedBox(height: AkelDesign.md),
                if (_isRecordingAudio) ...[
                  Text(
                    _formatDuration(_audioRecordingDuration),
                    style: AkelDesign.h2.copyWith(
                      color: AkelDesign.primaryRed,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: AkelDesign.md),
                ] else ...[
                  Text(
                    'Background audio recording',
                    style: AkelDesign.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AkelDesign.md),
                ],
                const SizedBox(height: AkelDesign.xl),
                FuturisticButton(
                  text: _isRecordingAudio ? 'STOP RECORDING' : 'START RECORDING',
                  icon: _isRecordingAudio ? Icons.stop : Icons.mic,
                  onPressed: _toggleAudioRecording,
                  color: _isRecordingAudio ? AkelDesign.primaryRed : AkelDesign.successGreen,
                  isFullWidth: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.xl),

          // Statistics
          Text('AUDIO STATISTICS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          _buildStatCard(
            'Audio Recordings',
            '${_stats['audio'] ?? 0}',
            Icons.audiotrack,
            Colors.purple,
          ),

          const SizedBox(height: AkelDesign.xl),

          // Info
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AkelDesign.infoBlue, size: 20),
                const SizedBox(width: AkelDesign.md),
                Expanded(
                  child: Text(
                    'Audio recordings continue in background. Stop when done.',
                    style: AkelDesign.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 3: VIDEO RECORDING ====================

  Widget _buildVideoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        children: [
          // Recording Interface
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.xxl),
            hasGlow: _isRecordingVideo,
            glowColor: AkelDesign.primaryRed,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _recordingAnimController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRecordingVideo ? 1.0 + (_recordingAnimController.value * 0.1) : 1.0,
                      child: Icon(
                        _isRecordingVideo ? Icons.videocam : Icons.videocam_outlined,
                        size: 80,
                        color: _isRecordingVideo ? AkelDesign.primaryRed : AkelDesign.neonBlue,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AkelDesign.lg),
                Text(
                  _isRecordingVideo ? 'RECORDING...' : 'VIDEO EVIDENCE',
                  style: AkelDesign.h3.copyWith(
                    color: _isRecordingVideo ? AkelDesign.primaryRed : AkelDesign.neonBlue,
                  ),
                ),
                const SizedBox(height: AkelDesign.md),
                if (_isRecordingVideo) ...[
                  Text(
                    _formatDuration(_videoRecordingDuration),
                    style: AkelDesign.h2.copyWith(
                      color: AkelDesign.primaryRed,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: AkelDesign.md),
                ] else ...[
                  Text(
                    'Stealth video recording available',
                    style: AkelDesign.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AkelDesign.md),
                ],
                const SizedBox(height: AkelDesign.xl),
                FuturisticButton(
                  text: _isRecordingVideo ? 'STOP RECORDING' : 'START RECORDING',
                  icon: _isRecordingVideo ? Icons.stop : Icons.videocam,
                  onPressed: _toggleVideoRecording,
                  color: _isRecordingVideo ? AkelDesign.primaryRed : AkelDesign.successGreen,
                  isFullWidth: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.xl),

          // Statistics
          Text('VIDEO STATISTICS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          _buildStatCard(
            'Video Recordings',
            '${_stats['video'] ?? 0}',
            Icons.video_library,
            Colors.deepOrange,
          ),

          const SizedBox(height: AkelDesign.xl),

          // Info
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: Row(
              children: [
                const Icon(Icons.security, color: AkelDesign.warningOrange, size: 20),
                const SizedBox(width: AkelDesign.md),
                Expanded(
                  child: Text(
                    'Videos can be recorded in stealth mode for safety',
                    style: AkelDesign.caption.copyWith(color: AkelDesign.warningOrange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 4: EVIDENCE VAULT ====================

  Widget _buildVaultTab() {
    final photoItems = _evidenceItems.where((e) => e.type == EvidenceType.photo).toList();
    final audioItems = _evidenceItems.where((e) => e.type == EvidenceType.audio).toList();
    final videoItems = _evidenceItems.where((e) => e.type == EvidenceType.video).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vault Statistics
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.lg),
            hasGlow: true,
            glowColor: AkelDesign.successGreen,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildVaultStat('Total', '${_stats['total'] ?? 0}', Icons.folder),
                _buildVaultStat('Encrypted', '${_stats['encrypted'] ?? 0}', Icons.lock),
                _buildVaultStat('Uploaded', '${_stats['uploaded'] ?? 0}', Icons.cloud_done),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.xl),

          if (_evidenceItems.isEmpty) ...[
            _buildEmptyState(),
          ] else ...[
            // Photos Section
            if (photoItems.isNotEmpty) ...[
              Text('PHOTOS (${photoItems.length})', style: AkelDesign.subtitle),
              const SizedBox(height: AkelDesign.md),
              ...photoItems.map((item) => _buildEvidenceCard(item)),
              const SizedBox(height: AkelDesign.lg),
            ],

            // Audio Section
            if (audioItems.isNotEmpty) ...[
              Text('AUDIO (${audioItems.length})', style: AkelDesign.subtitle),
              const SizedBox(height: AkelDesign.md),
              ...audioItems.map((item) => _buildEvidenceCard(item)),
              const SizedBox(height: AkelDesign.lg),
            ],

            // Video Section
            if (videoItems.isNotEmpty) ...[
              Text('VIDEO (${videoItems.length})', style: AkelDesign.subtitle),
              const SizedBox(height: AkelDesign.md),
              ...videoItems.map((item) => _buildEvidenceCard(item)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(EvidenceItem item) {
    IconData icon;
    Color color;

    switch (item.type) {
      case EvidenceType.photo:
        icon = Icons.photo;
        color = AkelDesign.neonBlue;
        break;
      case EvidenceType.audio:
        icon = Icons.audiotrack;
        color = Colors.purple;
        break;
      case EvidenceType.video:
        icon = Icons.videocam;
        color = Colors.deepOrange;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AkelDesign.md),
      child: FuturisticCard(
        padding: const EdgeInsets.all(AkelDesign.md),
        child: Row(
          children: [
            // Thumbnail/Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
              ),
              child: item.type == EvidenceType.photo && File(item.filePath).existsSync()
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                child: Image.file(
                  File(item.filePath),
                  fit: BoxFit.cover,
                ),
              )
                  : Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: AkelDesign.md),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(item.timestamp),
                    style: AkelDesign.caption,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item.isEncrypted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AkelDesign.successGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock, size: 10, color: AkelDesign.successGreen),
                              const SizedBox(width: 2),
                              Text(
                                'Encrypted',
                                style: AkelDesign.caption.copyWith(
                                  fontSize: 9,
                                  color: AkelDesign.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (item.isUploaded) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AkelDesign.infoBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_done, size: 10, color: AkelDesign.infoBlue),
                              const SizedBox(width: 2),
                              Text(
                                'Backed Up',
                                style: AkelDesign.caption.copyWith(
                                  fontSize: 9,
                                  color: AkelDesign.infoBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white60),
              color: AkelDesign.darkPanel,
              onSelected: (value) async {
                switch (value) {
                  case 'encrypt':
                    await _evidenceService.encryptEvidence(item.id);
                    await _loadEvidence();
                    await _loadStats();
                    break;
                  case 'upload':
                    await _evidenceService.uploadEvidence(item.id);
                    await _loadEvidence();
                    await _loadStats();
                    break;
                  case 'delete':
                    await _evidenceService.deleteEvidence(item.id);
                    await _loadEvidence();
                    await _loadStats();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (!item.isEncrypted)
                  const PopupMenuItem(
                    value: 'encrypt',
                    child: Row(
                      children: [
                        Icon(Icons.lock, size: 18, color: AkelDesign.successGreen),
                        SizedBox(width: 8),
                        Text('Encrypt', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                if (!item.isUploaded)
                  const PopupMenuItem(
                    value: 'upload',
                    child: Row(
                      children: [
                        Icon(Icons.cloud_upload, size: 18, color: AkelDesign.infoBlue),
                        SizedBox(width: 8),
                        Text('Upload', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: AkelDesign.errorRed),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.white24,
          ),
          const SizedBox(height: AkelDesign.lg),
          Text(
            'No Evidence Collected',
            style: AkelDesign.h3.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: AkelDesign.sm),
          Text(
            'Use Photo, Audio, or Video tabs to collect evidence',
            style: AkelDesign.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AkelDesign.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AkelDesign.h3.copyWith(color: color, fontSize: 20),
                ),
                Text(label, style: AkelDesign.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaultStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AkelDesign.successGreen, size: 32),
        const SizedBox(height: AkelDesign.sm),
        Text(
          value,
          style: AkelDesign.h3.copyWith(color: AkelDesign.successGreen, fontSize: 24),
        ),
        Text(label, style: AkelDesign.caption),
      ],
    );
  }

  Widget _buildInfoStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AkelDesign.sm),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AkelDesign.neonBlue.withOpacity(0.2),
              border: Border.all(color: AkelDesign.neonBlue, width: 1),
            ),
            child: Center(
              child: Text(
                number,
                style: AkelDesign.caption.copyWith(
                  color: AkelDesign.neonBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Text(text, style: AkelDesign.caption),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}