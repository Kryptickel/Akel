class VoiceCommand {
  final String id;
  final String userId;
  final String command;
  final DateTime timestamp;
  final bool triggered;
  final double confidence;

  VoiceCommand({
    required this.id,
    required this.userId,
    required this.command,
    required this.timestamp,
    this.triggered = false,
    this.confidence = 0.0,
  });

  factory VoiceCommand.fromMap(Map<String, dynamic> map, String id) {
    return VoiceCommand(
      id: id,
      userId: map['userId'] ?? '',
      command: map['command'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      triggered: map['triggered'] ?? false,
      confidence: (map['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'command': command,
      'timestamp': timestamp.toIso8601String(),
      'triggered': triggered,
      'confidence': confidence,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}