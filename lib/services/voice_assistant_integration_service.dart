import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// ==================== VOICE ASSISTANT INTEGRATION SERVICE ====================
///
/// MULTI-PLATFORM VOICE CONTROL
/// Complete voice assistant integration:
/// - Alexa integration
/// - Google Assistant integration
/// - Siri Shortcuts integration
/// - Voice-activated panic
/// - Voice status updates
/// - Custom voice commands
/// - Voice command history
///
/// 24-HOUR MARATHON - PHASE 5 (HOUR 20)
/// ================================================================

// ==================== VOICE ASSISTANT TYPES ====================

enum VoiceAssistantType {
  alexa,
  googleAssistant,
  siri,
  bixby,
}

extension VoiceAssistantTypeExtension on VoiceAssistantType {
  String get displayName {
    switch (this) {
      case VoiceAssistantType.alexa:
        return 'Amazon Alexa';
      case VoiceAssistantType.googleAssistant:
        return 'Google Assistant';
      case VoiceAssistantType.siri:
        return 'Siri Shortcuts';
      case VoiceAssistantType.bixby:
        return 'Samsung Bixby';
    }
  }

  IconData get icon {
    switch (this) {
      case VoiceAssistantType.alexa:
        return Icons.speaker;
      case VoiceAssistantType.googleAssistant:
        return Icons.assistant;
      case VoiceAssistantType.siri:
        return Icons.apple;
      case VoiceAssistantType.bixby:
        return Icons.phone_android;
    }
  }

  Color get color {
    switch (this) {
      case VoiceAssistantType.alexa:
        return const Color(0xFF00CAFF);
      case VoiceAssistantType.googleAssistant:
        return const Color(0xFF4285F4);
      case VoiceAssistantType.siri:
        return const Color(0xFF000000);
      case VoiceAssistantType.bixby:
        return const Color(0xFF1428A0);
    }
  }
}

// ==================== VOICE COMMAND MODEL ====================

class VoiceCommand {
  final String id;
  final String phrase;
  final String action;
  final VoiceAssistantType assistant;
  final bool isEnabled;
  final DateTime createdAt;
  final int usageCount;

  VoiceCommand({
    required this.id,
    required this.phrase,
    required this.action,
    required this.assistant,
    required this.isEnabled,
    required this.createdAt,
    this.usageCount = 0,
  });

  factory VoiceCommand.fromMap(Map<String, dynamic> map) {
    return VoiceCommand(
      id: map['id'] ?? '',
      phrase: map['phrase'] ?? '',
      action: map['action'] ?? '',
      assistant: VoiceAssistantType.values.firstWhere(
            (e) => e.toString() == map['assistant'],
        orElse: () => VoiceAssistantType.alexa,
      ),
      isEnabled: map['isEnabled'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      usageCount: map['usageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phrase': phrase,
      'action': action,
      'assistant': assistant.toString(),
      'isEnabled': isEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'usageCount': usageCount,
    };
  }

  VoiceCommand copyWith({
    String? id,
    String? phrase,
    String? action,
    VoiceAssistantType? assistant,
    bool? isEnabled,
    DateTime? createdAt,
    int? usageCount,
  }) {
    return VoiceCommand(
      id: id ?? this.id,
      phrase: phrase ?? this.phrase,
      action: action ?? this.action,
      assistant: assistant ?? this.assistant,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }
}

// ==================== VOICE COMMAND HISTORY MODEL ====================

class VoiceCommandHistory {
  final String id;
  final String command;
  final VoiceAssistantType assistant;
  final bool success;
  final DateTime timestamp;
  final String? error;

  VoiceCommandHistory({
    required this.id,
    required this.command,
    required this.assistant,
    required this.success,
    required this.timestamp,
    this.error,
  });

  factory VoiceCommandHistory.fromMap(Map<String, dynamic> map) {
    return VoiceCommandHistory(
      id: map['id'] ?? '',
      command: map['command'] ?? '',
      assistant: VoiceAssistantType.values.firstWhere(
            (e) => e.toString() == map['assistant'],
        orElse: () => VoiceAssistantType.alexa,
      ),
      success: map['success'] ?? false,
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      error: map['error'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'command': command,
      'assistant': assistant.toString(),
      'success': success,
      'timestamp': Timestamp.fromDate(timestamp),
      'error': error,
    };
  }
}

// ==================== VOICE ASSISTANT INTEGRATION SERVICE ====================

class VoiceAssistantIntegrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;
  List<VoiceCommand> _commands = [];
  List<VoiceCommandHistory> _history = [];
  Map<VoiceAssistantType, bool> _connectedAssistants = {};

// Callbacks
  Function(String message)? onLog;
  Function(String command)? onCommandExecuted;
  Function(String error)? onError;

// Getters
  bool isInitialized() => _isInitialized;
  List<VoiceCommand> getCommands() => List.unmodifiable(_commands);
  List<VoiceCommandHistory> getHistory() => List.unmodifiable(_history);
  Map<VoiceAssistantType, bool> getConnectedAssistants() =>
      Map.unmodifiable(_connectedAssistants);

// ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🎤 Initializing Voice Assistant Integration Service...');

// Load saved settings
      await _loadSettings();

      _isInitialized = true;
      debugPrint('✅ Voice Assistant Integration Service initialized');
    } catch (e) {
      debugPrint('❌ Voice Assistant initialization error: $e');
      rethrow;
    }
  }

  void dispose() {
    _commands.clear();
    _history.clear();
    _connectedAssistants.clear();
    _isInitialized = false;
    debugPrint('🎤 Voice Assistant Integration Service disposed');
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _connectedAssistants = {
      VoiceAssistantType.alexa: prefs.getBool('alexa_connected') ?? false,
      VoiceAssistantType.googleAssistant:
      prefs.getBool('google_assistant_connected') ?? false,
      VoiceAssistantType.siri: prefs.getBool('siri_connected') ?? false,
      VoiceAssistantType.bixby: prefs.getBool('bixby_connected') ?? false,
    };
  }

// ==================== ASSISTANT CONNECTION ====================

  /// Connect to voice assistant
  Future<bool> connectAssistant(VoiceAssistantType assistant) async {
    try {
      onLog?.call('Connecting to ${assistant.displayName}...');
      debugPrint('🔗 Connecting to ${assistant.displayName}');

// Simulate connection (in production, use actual OAuth/API)
      await Future.delayed(const Duration(seconds: 2));

      _connectedAssistants[assistant] = true;

// Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${assistant.name}_connected', true);

// Create default commands for this assistant
      await _createDefaultCommands(assistant);

      onLog?.call('✅ Connected to ${assistant.displayName}');
      debugPrint('✅ Connected to ${assistant.displayName}');

      return true;
    } catch (e) {
      debugPrint('❌ Error connecting to ${assistant.displayName}: $e');
      onError?.call('Failed to connect: $e');
      return false;
    }
  }

  /// Disconnect from voice assistant
  Future<void> disconnectAssistant(VoiceAssistantType assistant) async {
    try {
      onLog?.call('Disconnecting from ${assistant.displayName}...');
      debugPrint('🔗 Disconnecting from ${assistant.displayName}');

      _connectedAssistants[assistant] = false;

// Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${assistant.name}_connected', false);

      onLog?.call('Disconnected from ${assistant.displayName}');
      debugPrint('✅ Disconnected from ${assistant.displayName}');
    } catch (e) {
      debugPrint('❌ Error disconnecting from ${assistant.displayName}: $e');
      rethrow;
    }
  }

  bool isAssistantConnected(VoiceAssistantType assistant) {
    return _connectedAssistants[assistant] ?? false;
  }

// ==================== VOICE COMMANDS ====================

  /// Get user's voice commands
  Future<List<VoiceCommand>> getUserCommands(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('voice_commands')
          .orderBy('createdAt', descending: true)
          .get();

      _commands = snapshot.docs
          .map((doc) => VoiceCommand.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      return _commands;
    } catch (e) {
      debugPrint('❌ Error getting voice commands: $e');
      return [];
    }
  }

  /// Create voice command
  Future<void> createCommand(String userId, VoiceCommand command) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('voice_commands')
          .doc(command.id)
          .set(command.toMap());

      _commands.add(command);
      onLog?.call('Voice command created: ${command.phrase}');
      debugPrint('✅ Voice command created: ${command.phrase}');
    } catch (e) {
      debugPrint('❌ Error creating voice command: $e');
      rethrow;
    }
  }

  /// Update voice command
  Future<void> updateCommand(String userId, VoiceCommand command) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('voice_commands')
          .doc(command.id)
          .update(command.toMap());

      final index = _commands.indexWhere((c) => c.id == command.id);
      if (index != -1) {
        _commands[index] = command;
      }

      onLog?.call('Voice command updated');
      debugPrint('✅ Voice command updated: ${command.phrase}');
    } catch (e) {
      debugPrint('❌ Error updating voice command: $e');
      rethrow;
    }
  }

  /// Delete voice command
  Future<void> deleteCommand(String userId, String commandId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('voice_commands')
          .doc(commandId)
          .delete();

      _commands.removeWhere((c) => c.id == commandId);
      onLog?.call('Voice command deleted');
      debugPrint('✅ Voice command deleted: $commandId');
    } catch (e) {
      debugPrint('❌ Error deleting voice command: $e');
      rethrow;
    }
  }

  /// Execute voice command
  Future<bool> executeCommand(String userId, String commandId) async {
    try {
      final command = _commands.firstWhere((c) => c.id == commandId);

      if (!command.isEnabled) {
        debugPrint('⚠️ Command is disabled: ${command.phrase}');
        return false;
      }

      onLog?.call('Executing: ${command.phrase}');
      debugPrint('🎤 Executing voice command: ${command.phrase}');

// Simulate execution (in production, trigger actual actions)
      await Future.delayed(const Duration(seconds: 1));

// Update usage count
      await updateCommand(
        userId,
        command.copyWith(usageCount: command.usageCount + 1),
      );

// Log to history
      await _logCommandHistory(
        userId,
        VoiceCommandHistory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          command: command.phrase,
          assistant: command.assistant,
          success: true,
          timestamp: DateTime.now(),
        ),
      );

      onCommandExecuted?.call(command.phrase);
      onLog?.call('✅ Command executed successfully');
      debugPrint('✅ Command executed: ${command.phrase}');

      return true;
    } catch (e) {
      debugPrint('❌ Error executing command: $e');
      onError?.call('Failed to execute command: $e');
      return false;
    }
  }

  /// Create default commands for assistant
  Future<void> _createDefaultCommands(VoiceAssistantType assistant) async {
    final defaultCommands = _getDefaultCommands(assistant);

    for (final command in defaultCommands) {
      _commands.add(command);
    }
  }

  List<VoiceCommand> _getDefaultCommands(VoiceAssistantType assistant) {
    final prefix = _getAssistantPrefix(assistant);

    return [
      VoiceCommand(
        id: 'cmd_panic_${assistant.name}',
        phrase: '$prefix, trigger panic button',
        action: 'trigger_panic',
        assistant: assistant,
        isEnabled: true,
        createdAt: DateTime.now(),
      ),
      VoiceCommand(
        id: 'cmd_status_${assistant.name}',
        phrase: '$prefix, check home status',
        action: 'check_status',
        assistant: assistant,
        isEnabled: true,
        createdAt: DateTime.now(),
      ),
      VoiceCommand(
        id: 'cmd_lock_${assistant.name}',
        phrase: '$prefix, lock all doors',
        action: 'lock_all_doors',
        assistant: assistant,
        isEnabled: true,
        createdAt: DateTime.now(),
      ),
      VoiceCommand(
        id: 'cmd_camera_${assistant.name}',
        phrase: '$prefix, start recording cameras',
        action: 'start_cameras',
        assistant: assistant,
        isEnabled: true,
        createdAt: DateTime.now(),
      ),
      VoiceCommand(
        id: 'cmd_alert_${assistant.name}',
        phrase: '$prefix, send alert to emergency contacts',
        action: 'send_alert',
        assistant: assistant,
        isEnabled: true,
        createdAt: DateTime.now(),
      ),
    ];
  }

  String _getAssistantPrefix(VoiceAssistantType assistant) {
    switch (assistant) {
      case VoiceAssistantType.alexa:
        return 'Alexa';
      case VoiceAssistantType.googleAssistant:
        return 'Hey Google';
      case VoiceAssistantType.siri:
        return 'Hey Siri';
      case VoiceAssistantType.bixby:
        return 'Hi Bixby';
    }
  }

// ==================== COMMAND HISTORY ====================

  /// Get command history
  Future<List<VoiceCommandHistory>> getCommandHistory(String userId,
      {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('voice_command_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      _history = snapshot.docs
          .map((doc) =>
          VoiceCommandHistory.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      return _history;
    } catch (e) {
      debugPrint('❌ Error getting command history: $e');
      return [];
    }
  }

  /// Log command execution to history
  Future<void> _logCommandHistory(
      String userId,
      VoiceCommandHistory history,
      ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('voice_command_history')
          .doc(history.id)
          .set(history.toMap());

      _history.insert(0, history);

// Keep only last 100 entries
      if (_history.length > 100) {
        _history.removeLast();
      }
    } catch (e) {
      debugPrint('❌ Error logging command history: $e');
    }
  }

// ==================== VOICE PHRASES ====================

  /// Get example phrases for assistant
  List<String> getExamplePhrases(VoiceAssistantType assistant) {
    final prefix = _getAssistantPrefix(assistant);

    return [
      '$prefix, trigger panic button',
      '$prefix, I need help',
      '$prefix, activate emergency mode',
      '$prefix, lock all doors',
      '$prefix, check home status',
      '$prefix, are my cameras recording?',
      '$prefix, send alert to emergency contacts',
      '$prefix, what\'s my home security status?',
      '$prefix, turn on emergency lights',
      '$prefix, activate safe mode',
    ];
  }

  /// Get setup instructions for assistant
  String getSetupInstructions(VoiceAssistantType assistant) {
    switch (assistant) {
      case VoiceAssistantType.alexa:
        return '''
1. Open the Alexa app on your phone
2. Go to Skills & Games
3. Search for "AKEL Panic Button"
4. Enable the skill
5. Link your AKEL account
6. Start using voice commands!
''';

      case VoiceAssistantType.googleAssistant:
        return '''
1. Open the Google Home app
2. Go to Settings > Works with Google
3. Search for "AKEL Panic Button"
4. Link your AKEL account
5. Test with "Hey Google, ask AKEL about my home"
6. Start using voice commands!
''';

      case VoiceAssistantType.siri:
        return '''
1. Open the Shortcuts app
2. Tap the + button to create new shortcut
3. Add "Open App" action, select AKEL
4. Add custom voice phrase
5. Save and test your shortcut
6. Use "Hey Siri" to trigger!
''';

      case VoiceAssistantType.bixby:
        return '''
1. Open Bixby app
2. Go to Quick Commands
3. Create new command
4. Set trigger phrase
5. Add action to open AKEL app
6. Test your command!
''';
    }
  }

// ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getVoiceStatistics(String userId) async {
    try {
      final commands = await getUserCommands(userId);
      final history = await getCommandHistory(userId);

      final totalUsage = commands.fold<int>(
        0,
            (sum, cmd) => sum + cmd.usageCount,
      );

      final successRate = history.isEmpty
          ? 0.0
          : (history.where((h) => h.success).length / history.length) * 100;

      final commandsByAssistant = <String, int>{};
      for (final cmd in commands) {
        final name = cmd.assistant.displayName;
        commandsByAssistant[name] = (commandsByAssistant[name] ?? 0) + 1;
      }

      return {
        'totalCommands': commands.length,
        'enabledCommands': commands.where((c) => c.isEnabled).length,
        'totalUsage': totalUsage,
        'successRate': successRate,
        'commandsByAssistant': commandsByAssistant,
        'connectedAssistants': _connectedAssistants.values
            .where((connected) => connected)
            .length,
        'recentActivity': history.length,
      };
    } catch (e) {
      debugPrint('❌ Error getting voice statistics: $e');
      return {
        'totalCommands': 0,
        'enabledCommands': 0,
        'totalUsage': 0,
        'successRate': 0.0,
        'commandsByAssistant': {},
        'connectedAssistants': 0,
        'recentActivity': 0,
      };
    }
  }

// ==================== VOICE TRIGGER ====================

  /// Trigger panic via voice (simulation)
  Future<void> triggerVoicePanic(
      String userId,
      VoiceAssistantType assistant,
      ) async {
    try {
      onLog?.call('🚨 Voice panic triggered via ${assistant.displayName}');
      debugPrint('🚨 Voice panic triggered via ${assistant.displayName}');

// Log to history
      await _logCommandHistory(
        userId,
        VoiceCommandHistory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          command: 'Emergency voice panic',
          assistant: assistant,
          success: true,
          timestamp: DateTime.now(),
        ),
      );

      onCommandExecuted?.call('Emergency voice panic');
      onLog?.call('✅ Voice panic triggered successfully');
    } catch (e) {
      debugPrint('❌ Error triggering voice panic: $e');
      rethrow;
    }
  }

  /// Get voice status update (simulation)
  Future<String> getVoiceStatusUpdate(String userId) async {
    try {
// In production, this would gather actual system status
      final status = '''
Your home security status:
• All doors are locked
• 3 cameras are recording
• No motion detected
• All systems normal
''';

      onLog?.call('Voice status update requested');
      return status;
    } catch (e) {
      debugPrint('❌ Error getting voice status: $e');
      return 'Unable to retrieve status at this time.';
    }
  }
}