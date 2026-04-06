enum MessageSender { user, ai, system }

class AIMessage {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isError;
  final Map<String, dynamic>? metadata;

  AIMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.isError = false,
    this.metadata,
  });

  factory AIMessage.user(String content) {
    return AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
  }

  factory AIMessage.ai(String content, {Map<String, dynamic>? metadata}) {
    return AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  factory AIMessage.system(String content, {bool isError = false}) {
    return AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      sender: MessageSender.system,
      timestamp: DateTime.now(),
      isError: isError,
    );
  }

  factory AIMessage.error(String content) {
    return AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      sender: MessageSender.system,
      timestamp: DateTime.now(),
      isError: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'sender': sender.toString(),
      'timestamp': timestamp.toIso8601String(),
      'isError': isError,
      'metadata': metadata,
    };
  }
}