class FakeCall {
  final String id;
  final String userId;
  final String callerName;
  final String callerNumber;
  final DateTime scheduledTime;
  final DateTime? triggeredTime;
  final bool completed;
  final int delaySeconds;

  FakeCall({
    required this.id,
    required this.userId,
    required this.callerName,
    required this.callerNumber,
    required this.scheduledTime,
    this.triggeredTime,
    this.completed = false,
    required this.delaySeconds,
  });

  factory FakeCall.fromMap(Map<String, dynamic> map, String id) {
    return FakeCall(
      id: id,
      userId: map['userId'] ?? '',
      callerName: map['callerName'] ?? 'Unknown',
      callerNumber: map['callerNumber'] ?? '',
      scheduledTime: DateTime.parse(map['scheduledTime']),
      triggeredTime: map['triggeredTime'] != null
          ? DateTime.parse(map['triggeredTime'])
          : null,
      completed: map['completed'] ?? false,
      delaySeconds: map['delaySeconds'] ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'callerName': callerName,
      'callerNumber': callerNumber,
      'scheduledTime': scheduledTime.toIso8601String(),
      'triggeredTime': triggeredTime?.toIso8601String(),
      'completed': completed,
      'delaySeconds': delaySeconds,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  FakeCall copyWith({
    String? id,
    String? userId,
    String? callerName,
    String? callerNumber,
    DateTime? scheduledTime,
    DateTime? triggeredTime,
    bool? completed,
    int? delaySeconds,
  }) {
    return FakeCall(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      callerName: callerName ?? this.callerName,
      callerNumber: callerNumber ?? this.callerNumber,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      triggeredTime: triggeredTime ?? this.triggeredTime,
      completed: completed ?? this.completed,
      delaySeconds: delaySeconds ?? this.delaySeconds,
    );
  }
}