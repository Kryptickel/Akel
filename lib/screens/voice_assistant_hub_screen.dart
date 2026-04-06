import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import '../widgets/futuristic_widgets.dart';
import '../services/voice_assistant_integration_service.dart';
import '../providers/auth_provider.dart';

/// ==================== VOICE ASSISTANT HUB SCREEN ====================
///
/// VOICE CONTROL CENTER
/// Complete voice assistant integration interface:
/// - Connect assistants (Alexa, Google, Siri, Bixby)
/// - Manage voice commands
/// - View command history
/// - Test voice commands
/// - Setup instructions
/// - Usage statistics
///
/// 24-HOUR MARATHON - PHASE 5 (HOUR 20)
/// ================================================================

class VoiceAssistantHubScreen extends StatefulWidget {
  const VoiceAssistantHubScreen({Key? key}) : super(key: key);

  @override
  State<VoiceAssistantHubScreen> createState() =>
      _VoiceAssistantHubScreenState();
}

class _VoiceAssistantHubScreenState extends State<VoiceAssistantHubScreen>
    with TickerProviderStateMixin {
  final VoiceAssistantIntegrationService _voiceService =
  VoiceAssistantIntegrationService();

  late TabController _tabController;
  late AnimationController _pulseController;

  bool _isInitializing = true;
  List<VoiceCommand> _commands = [];
  List<VoiceCommandHistory> _history = [];
  Map<VoiceAssistantType, bool> _connectedAssistants = {};
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _voiceService.onLog = (message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    };

    _initializeHub();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _initializeHub() async {
    setState(() => _isInitializing = true);

    try {
      await _voiceService.initialize();
      await _loadData();

      setState(() => _isInitializing = false);
    } catch (e) {
      debugPrint(' Hub initialization error: $e');
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      final commands = await _voiceService.getUserCommands(userId);
      final history = await _voiceService.getCommandHistory(userId);
      final connected = _voiceService.getConnectedAssistants();
      final stats = await _voiceService.getVoiceStatistics(userId);

      if (mounted) {
        setState(() {
          _commands = commands;
          _history = history;
          _connectedAssistants = connected;
          _statistics = stats;
        });
      }
    }
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
                color: Colors.purple,
              ),
              SizedBox(height: AkelDesign.xl),
              Text(
                'Loading Voice Hub...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
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
              'VOICE ASSISTANT HUB',
              style: AkelDesign.h3.copyWith(fontSize: 16),
            ),
            Text(
              'Voice Control Center',
              style: AkelDesign.caption.copyWith(fontSize: 10),
            ),
          ],
        ),
        actions: [
          FuturisticIconButton(
            icon: Icons.refresh,
            onPressed: _handleRefresh,
            size: 40,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.purple,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Assistants'),
            Tab(text: 'Commands'),
            Tab(text: 'History'),
            Tab(text: 'Statistics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssistantsTab(),
          _buildCommandsTab(),
          _buildHistoryTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  // ==================== TAB 1: ASSISTANTS ====================

  Widget _buildAssistantsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CONNECT VOICE ASSISTANTS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          ...(VoiceAssistantType.values.map((assistant) => Padding(
            padding: const EdgeInsets.only(bottom: AkelDesign.md),
            child: _buildAssistantCard(assistant),
          ))),
        ],
      ),
    );
  }

  Widget _buildAssistantCard(VoiceAssistantType assistant) {
    final isConnected = _connectedAssistants[assistant] ?? false;

    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.lg),
      hasGlow: isConnected,
      glowColor: assistant.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: assistant.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  assistant.icon,
                  color: assistant.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: AkelDesign.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assistant.displayName,
                      style: AkelDesign.body.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isConnected ? 'Connected' : 'Not Connected',
                      style: AkelDesign.caption.copyWith(
                        color: isConnected
                            ? AkelDesign.successGreen
                            : Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              if (isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AkelDesign.sm,
                    vertical: AkelDesign.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AkelDesign.successGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
                    border: Border.all(color: AkelDesign.successGreen),
                  ),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AkelDesign.successGreen,
                              boxShadow: [
                                BoxShadow(
                                  color: AkelDesign.successGreen,
                                  blurRadius:
                                  3 + (_pulseController.value * 2),
                                  spreadRadius:
                                  1 + (_pulseController.value),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ACTIVE',
                        style: AkelDesign.caption.copyWith(
                          color: AkelDesign.successGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: AkelDesign.md),

          Row(
            children: [
              Expanded(
                child: FuturisticButton(
                  text: isConnected ? 'DISCONNECT' : 'CONNECT',
                  icon: isConnected ? Icons.link_off : Icons.link,
                  onPressed: () => _handleAssistantConnection(assistant),
                  color: isConnected ? AkelDesign.errorRed : assistant.color,
                  isOutlined: true,
                  isSmall: true,
                ),
              ),
              const SizedBox(width: AkelDesign.sm),
              Expanded(
                child: FuturisticButton(
                  text: 'SETUP',
                  icon: Icons.info_outline,
                  onPressed: () => _showSetupInstructions(assistant),
                  color: AkelDesign.neonBlue,
                  isOutlined: true,
                  isSmall: true,
                ),
              ),
            ],
          ),

          if (isConnected) ...[
            const SizedBox(height: AkelDesign.md),
            const Divider(color: Colors.white10),
            const SizedBox(height: AkelDesign.sm),

            Text(
              'EXAMPLE PHRASES',
              style: AkelDesign.caption.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: AkelDesign.sm),

            ...(_voiceService
                .getExamplePhrases(assistant)
                .take(3)
                .map((phrase) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.mic,
                    size: 14,
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      phrase,
                      style: AkelDesign.caption.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ))),
          ],
        ],
      ),
    );
  }

  // ==================== TAB 2: COMMANDS ====================

  Widget _buildCommandsTab() {
    if (_commands.isEmpty) {
      return _buildEmptyState(
        icon: Icons.mic_off,
        title: 'No Voice Commands',
        subtitle: 'Connect an assistant to\ncreate voice commands',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AkelDesign.lg),
      itemCount: _commands.length,
      itemBuilder: (context, index) {
        final command = _commands[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AkelDesign.md),
          child: _buildCommandCard(command),
        );
      },
    );
  }

  Widget _buildCommandCard(VoiceCommand command) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.lg),
      hasGlow: command.isEnabled,
      glowColor: command.assistant.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: command.assistant.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  command.assistant.icon,
                  color: command.assistant.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: AkelDesign.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      command.phrase,
                      style: AkelDesign.body.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      command.assistant.displayName,
                      style: AkelDesign.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch(
                value: command.isEnabled,
                onChanged: (value) {
                  // Toggle command
                },
                activeColor: command.assistant.color,
              ),
            ],
          ),

          const SizedBox(height: AkelDesign.sm),

          Row(
            children: [
              Text(
                'Used ${command.usageCount} times',
                style: AkelDesign.caption.copyWith(fontSize: 11),
              ),
              const SizedBox(width: AkelDesign.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AkelDesign.neonBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  command.action,
                  style: AkelDesign.caption.copyWith(
                    fontSize: 9,
                    color: AkelDesign.neonBlue,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AkelDesign.md),

          FuturisticButton(
            text: 'TEST COMMAND',
            icon: Icons.play_arrow,
            onPressed: () => _handleTestCommand(command),
            color: AkelDesign.successGreen,
            isOutlined: true,
            isFullWidth: true,
            isSmall: true,
          ),
        ],
      ),
    );
  }

  // ==================== TAB 3: HISTORY ====================

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No History',
        subtitle: 'Voice command history\nwill appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AkelDesign.lg),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final history = _history[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AkelDesign.sm),
          child: _buildHistoryCard(history),
        );
      },
    );
  }

  Widget _buildHistoryCard(VoiceCommandHistory history) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: history.assistant.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              history.assistant.icon,
              color: history.assistant.color,
              size: 18,
            ),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.command,
                  style: AkelDesign.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimestamp(history.timestamp),
                  style: AkelDesign.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Icon(
            history.success ? Icons.check_circle : Icons.error,
            color: history.success
                ? AkelDesign.successGreen
                : AkelDesign.errorRed,
            size: 18,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // ==================== TAB 4: STATISTICS ====================

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VOICE STATISTICS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Commands',
                  '${_statistics['totalCommands'] ?? 0}',
                  Icons.mic,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: AkelDesign.md),
              Expanded(
                child: _buildStatCard(
                  'Connected',
                  '${_statistics['connectedAssistants'] ?? 0}',
                  Icons.link,
                  AkelDesign.successGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: AkelDesign.md),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Usage',
                  '${_statistics['totalUsage'] ?? 0}',
                  Icons.trending_up,
                  AkelDesign.neonBlue,
                ),
              ),
              const SizedBox(width: AkelDesign.md),
              Expanded(
                child: _buildStatCard(
                  'Success Rate',
                  '${(_statistics['successRate'] ?? 0).toStringAsFixed(0)}%',
                  Icons.check_circle,
                  AkelDesign.successGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AkelDesign.sm),
          Text(
            value,
            style: AkelDesign.h3.copyWith(color: color, fontSize: 24),
          ),
          Text(
            label,
            style: AkelDesign.caption.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AkelDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.white24),
            const SizedBox(height: AkelDesign.lg),
            Text(
              title,
              style: AkelDesign.h3.copyWith(color: Colors.white60),
            ),
            const SizedBox(height: AkelDesign.sm),
            Text(
              subtitle,
              style: AkelDesign.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HANDLERS ====================

  void _handleRefresh() {
    _performRefresh();
  }

  Future<void> _performRefresh() async {
    await _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(' Refreshed successfully'),
        backgroundColor: AkelDesign.successGreen,
      ),
    );
  }

  void _handleAssistantConnection(VoiceAssistantType assistant) {
    _performConnection(assistant);
  }

  Future<void> _performConnection(VoiceAssistantType assistant) async {
    final isConnected = _connectedAssistants[assistant] ?? false;

    if (isConnected) {
      // Disconnect
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AkelDesign.darkPanel,
          title: Text(
            'Disconnect ${assistant.displayName}?',
            style: AkelDesign.h3,
          ),
          content: Text(
            'This will disable all voice commands for ${assistant.displayName}.',
            style: AkelDesign.body,
          ),
          actions: [
            FuturisticButton(
              text: 'CANCEL',
              onPressed: () => Navigator.pop(context, false),
              isOutlined: true,
              isSmall: true,
            ),
            const SizedBox(width: 8),
            FuturisticButton(
              text: 'DISCONNECT',
              onPressed: () => Navigator.pop(context, true),
              color: AkelDesign.errorRed,
              isSmall: true,
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _voiceService.disconnectAssistant(assistant);
        await _loadData();
      }
    } else {
      // Connect
      final success = await _voiceService.connectAssistant(assistant);
      if (success) {
        await _loadData();
      }
    }
  }

  void _showSetupInstructions(VoiceAssistantType assistant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        title: Row(
          children: [
            Icon(assistant.icon, color: assistant.color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${assistant.displayName} Setup',
                style: AkelDesign.h3.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            _voiceService.getSetupInstructions(assistant),
            style: AkelDesign.body.copyWith(fontSize: 14),
          ),
        ),
        actions: [
          FuturisticButton(
            text: 'GOT IT',
            onPressed: () => Navigator.pop(context),
            color: assistant.color,
            isSmall: true,
          ),
        ],
      ),
    );
  }

  Future<void> _handleTestCommand(VoiceCommand command) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        title: Text('Testing Command', style: AkelDesign.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FuturisticLoadingIndicator(
              size: 40,
              color: Colors.purple,
            ),
            const SizedBox(height: AkelDesign.lg),
            Text(
              'Executing: "${command.phrase}"',
              style: AkelDesign.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      await _voiceService.executeCommand(userId, command.id);
      await _loadData();
    }

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' Command executed: ${command.phrase}'),
          backgroundColor: AkelDesign.successGreen,
        ),
      );
    }
  }
}
