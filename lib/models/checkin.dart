class CheckIn {
  final String id;
  final String userId;
  final DateTime scheduledTime;
  final DateTime? completedTime;
  final bool completed;
  final bool missed;
  final String? location;
  final String? notes;
  final String frequency; // 'once', 'hourly', 'daily', 'custom'
  final bool alertSent; // If missed and alert was sent

  CheckIn({
    required this.id,
    required this.userId,
    required this.scheduledTime,
    this.completedTime,
    this.completed = false,
    this.missed = false,
    this.location,
    this.notes,
    this.frequency = 'once',
    this.alertSent = false,
  });

  factory CheckIn.fromMap(Map<String, dynamic> map, String id) {
    return CheckIn(
      id: id,
      userId: map['userId'] ?? '',
      scheduledTime: DateTime.parse(map['scheduledTime']),
      completedTime: map['completedTime'] != null
          ? DateTime.parse(map['completedTime'])
          : null,
      completed: map['completed'] ?? false,
      missed: map['missed'] ?? false,
      location: map['location'],
      notes: map['notes'],
      frequency: map['frequency'] ?? 'once',
      alertSent: map['alertSent'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'completed': completed,
      'missed': missed,
      'location': location,
      'notes': notes,
      'frequency': frequency,
      'alertSent': alertSent,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  CheckIn copyWith({
    String? id,
    String? userId,
    DateTime? scheduledTime,
    DateTime? completedTime,
    bool? completed,
    bool? missed,
    String? location,
    String? notes,
    String? frequency,
    bool? alertSent,
  }) {
    return CheckIn(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      completedTime: completedTime ?? this.completedTime,
      completed: completed ?? this.completed,
      missed: missed ?? this.missed,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      frequency: frequency ?? this.frequency,
      alertSent: alertSent ?? this.alertSent,
    );
  }

  bool get isPending => !completed && !missed && DateTime.now().isBefore(scheduledTime);
  bool get isDue => !completed && !missed && DateTime.now().isAfter(scheduledTime);
  bool get isOverdue => isDue && DateTime.now().difference(scheduledTime).inMinutes > 15;
}